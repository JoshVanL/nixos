"""Dapr Agents on Diagrid Catalyst that catalyst-cron calls."""

import subprocess

from dapr_agents.agents.configs import WorkflowRetryPolicy

# Cap on text handed back to the LLM from one tool call.
MAX_OUTPUT = 20000

# Retries for the agents' activities, mainly LLM calls. Anthropic's API can
# answer 529 Overloaded for minutes at a time, longer than the default ~17s of
# retries. Waiting is a durable timer and failed calls are not billed, so
# retry for about 35 minutes: 30s, 1m, 2m, 4m, 8m, then every 10m.
RETRY = WorkflowRetryPolicy(
    max_attempts=8,
    initial_backoff_seconds=30,
    max_backoff_seconds=600,
    backoff_multiplier=2,
)


def run(args: list[str], cwd: str | None = None, timeout: int = 120, stderr: bool = False) -> str:
    """Run a command and return its stdout, followed by its stderr if stderr
    is set.

    On failure raises RuntimeError with the tail of stdout and stderr, which
    the agent sees as the tool's result.
    """
    # Build logs can hold bytes that are not UTF-8.
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, errors="replace", timeout=timeout)
    if p.returncode != 0:
        out = (p.stdout + p.stderr)[-MAX_OUTPUT:]
        raise RuntimeError(f"{args[0]} exited {p.returncode}:\n{out}")
    return (p.stdout + p.stderr if stderr else p.stdout)[:MAX_OUTPUT]
