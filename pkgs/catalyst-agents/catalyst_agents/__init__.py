"""Dapr Agents on Diagrid Catalyst that catalyst-cron calls."""

import subprocess

# Cap on text handed back to the LLM from one tool call.
MAX_OUTPUT = 20000


def run(args: list[str], cwd: str | None = None, timeout: int = 120) -> str:
    """Run a command and return its stdout.

    On failure raises RuntimeError with the tail of stdout and stderr, which
    the agent sees as the tool's result.
    """
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    if p.returncode != 0:
        out = (p.stdout + p.stderr)[-MAX_OUTPUT:]
        raise RuntimeError(f"{args[0]} exited {p.returncode}:\n{out}")
    return p.stdout[:MAX_OUTPUT]
