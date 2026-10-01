"""job-doctor explains why a catalyst-cron job's systemd unit failed.

Its tools only read: the journal, unit files, and files in the nix store.
"""

import glob
import os
import pwd
import re

from dapr_agents import DurableAgent, tool
from dapr_agents.agents.configs import AgentExecutionConfig, AgentMCPConfig

from catalyst_agents import MAX_OUTPUT, run

UNIT = re.compile(r"^[A-Za-z0-9@._:\\-]+$")


def _unit(unit: str) -> str:
    if not UNIT.match(unit):
        raise ValueError(f"invalid unit name {unit!r}")
    return unit


@tool
def journal(unit: str, user_unit: bool, since: str, until: str = "") -> str:
    """Return up to 300 journal lines of a systemd unit, oldest first.

    Args:
        unit: Unit name, e.g. zfs_uploader.service.
        user_unit: True for a user unit, False for a system unit.
        since: Start time in a form journalctl --since accepts, e.g. "2026-10-01 13:00:00".
        until: Optional end time in a form journalctl --until accepts.
    """
    args = ["journalctl", "--no-pager", "-o", "short-iso", "-n", "300", "--since", since]
    if until:
        args += ["--until", until]
    args += ["--user-unit" if user_unit else "--unit", _unit(unit)]
    return run(args)


def _unit_dirs(user_unit: bool) -> list[str]:
    # Read from disk: the sandbox has no access to the user's systemd manager.
    if not user_unit:
        return ["/etc/systemd/system"]
    home = pwd.getpwuid(os.getuid()).pw_dir
    return [os.path.join(home, ".config/systemd/user"), "/etc/systemd/user"]


@tool
def unit_file(unit: str, user_unit: bool) -> str:
    """Return a systemd unit's file and its drop-ins.

    Args:
        unit: Unit name, e.g. zfs_uploader.service.
        user_unit: True for a user unit, False for a system unit.
    """
    out = []
    for d in _unit_dirs(user_unit):
        for path in [os.path.join(d, _unit(unit)), *sorted(glob.glob(os.path.join(d, unit + ".d", "*.conf")))]:
            if os.path.isfile(path):
                with open(path, errors="replace") as f:
                    out.append(f"# {path}\n{f.read()}")
    if not out:
        raise ValueError(f"no unit file for {unit}")
    return "\n".join(out)[:MAX_OUTPUT]


@tool
def read_file(path: str) -> str:
    """Return a file from the nix store, such as a script a unit runs.

    Args:
        path: Absolute path under /nix/store.
    """
    real = os.path.realpath(path)
    if not real.startswith("/nix/store/"):
        raise ValueError("only files under /nix/store can be read")
    with open(real, errors="replace") as f:
        return f.read(MAX_OUTPUT)


def agent(llm) -> DurableAgent:
    return DurableAgent(
        name="job-doctor",
        role="Diagnoses failed scheduled jobs",
        goal="Find out why a systemd unit that catalyst-cron ran failed, and what to do about it.",
        instructions=[
            "The task names the unit, whether it is a user unit, when the run started, and the tail of its log.",
            "Read more of the journal around the run, the unit definition, and the scripts it runs, until the cause is clear.",
            "Reply in at most three short sentences: the cause, whether it is likely transient (the next run will pass) or needs a fix, and what to do.",
            "Only state what the logs show. If they are not enough, say what is missing.",
        ],
        llm=llm,
        tools=[journal, unit_file, read_file],
        execution=AgentExecutionConfig(max_iterations=10),
        mcp=AgentMCPConfig(enabled=False),
    )
