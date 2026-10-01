"""Serve the job-doctor and bump agents, and the bump workflow, on Catalyst."""

import asyncio
import json
import logging
import os

import dapr.ext.workflow as wf
from dapr_agents import DaprChatClient
from dapr_agents.workflow.utils.core import wait_for_shutdown

from catalyst_agents import bump, doctor


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    with open(os.environ.get("CATALYST_AGENTS_CONFIG", "/etc/catalyst-agents/config.json")) as f:
        cfg = json.load(f)

    llm = DaprChatClient(component_name=cfg["llmComponent"])
    # One runtime for everything: separate runtimes on one App ID would each
    # be sent work items for workflows that only another one registered.
    runtime = wf.WorkflowRuntime()
    for agent in [doctor.agent(llm), *bump.register(runtime, llm, cfg)]:
        agent.register(runtime)
    runtime.start()
    try:
        asyncio.run(wait_for_shutdown())
    finally:
        runtime.shutdown()
