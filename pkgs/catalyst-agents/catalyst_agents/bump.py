"""bump keeps pinned package versions in the NixOS config repo current.

The bump workflow does the fixed steps: a fresh git worktree on branch
bump/<target> from main, the target's agent, then a report of what got
committed. The agent finds the latest release, edits the pin, builds, and
commits on that branch. Nothing touches main or gets pushed; a human merges.
"""

import json
import os
import re
import shutil
import subprocess

import dapr.ext.workflow as wf
import requests
from dapr_agents import DurableAgent, tool
from dapr_agents.agents.configs import (
    AgentExecutionConfig,
    AgentMCPConfig,
    ToolExecutionMode,
)

from catalyst_agents import MAX_OUTPUT, run

STATE = os.environ.get("STATE_DIRECTORY", "/var/lib/catalyst-agents")
ATTR = re.compile(r"^[A-Za-z0-9_.-]*$")

INSTRUCTIONS = [
    "You keep one pinned package in a NixOS flake repo up to date. You work in a git worktree on its own branch, so your edits never touch main.",
    "1. Read the pin in the repo, then find the latest stable upstream release with fetch.",
    "2. If the pin is already the latest, reply 'up to date at <version>' and stop. Do not commit.",
    "3. Otherwise update the version and every hash. Get download hashes with prefetch. For hashes only a build reveals (vendorHash, cargoHash), set them to lib.fakeHash, build, and copy the correct hash from the error.",
    "4. Build until it passes. If it fails for a reason other than a hash, read the error and fix it in the repo. If you cannot, reply with the error and do not commit.",
    "5. Read the release notes between the old and new version. Commit with a first line '<path without .nix>: update <old> -> <new>', and a body listing only notes that matter here: breaking changes, removed or renamed options or flags, security fixes.",
    "6. Reply with one line: '<package> <old> -> <new>', plus anything a human must check before merging.",
    "Use search to find where something is defined before reading files.",
    "Never allow an insecure, broken or unfree package, or change nixpkgs config to get past a refusal. Reply with the package and the error instead, and do not commit.",
    "Never use em dashes.",
]


def review_steps(branch: str) -> list[str]:
    return [
        f"git show {branch}",
        f"git merge --ff-only {branch}",
        f"git branch -D {branch}",
    ]


def write_pending(repo: str) -> None:
    """Rewrite pending-review/bumps.md in the repo: how to land a bump, then
    every bump branch with commits not on main and their messages, which hold
    the release notes. Removed when there are none."""
    path = os.path.join(repo, "pending-review", "bumps.md")
    out = []
    branches = run(["git", "for-each-ref", "--format=%(refname:short)", "refs/heads/bump/"], cwd=repo)
    for b in branches.split():
        log = run(["git", "log", "--format=%s%n%n%b%x00", f"main..{b}"], cwd=repo)
        messages = [
            "\n".join(line for line in m.splitlines() if not line.startswith("Signed-off-by:")).strip()
            for m in log.split("\0") if m.strip()
        ]
        if messages:
            out += [f"## {b}", "", "\n\n".join(messages), ""]
    if not out:
        if os.path.exists(path):
            os.remove(path)
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write("\n".join([
            "# Bumps to review",
            "",
            "Rewritten by catalyst-agents after every bump run. Branches you merge or delete drop off at the next run.",
            "",
            "For each branch below:",
            "",
            "```sh",
            *review_steps("<branch>"),
            "```",
            "",
            *out,
        ]))


class Tree:
    """The git worktree that one target's agent edits."""

    def __init__(self, repo: str, target: str):
        self.repo = repo
        self.dir = os.path.join(STATE, "worktrees", target)
        self.branch = f"bump/{target}"
        # Git tree id of the content that last built, so commit refuses
        # unbuilt content, also after a restart.
        self.built_file = os.path.join(STATE, f"{target}.built")

    def git(self, *args: str, cwd: str | None = None) -> str:
        return run(["git", *args], cwd=cwd or self.dir)

    def path(self, rel: str) -> str:
        root = os.path.realpath(self.dir)
        p = os.path.realpath(os.path.join(root, rel))
        if not p.startswith(root + os.sep):
            raise ValueError(f"{rel!r} is outside the repo")
        return p

    def tree_id(self) -> str:
        # Staging first makes new files part of the id, and visible to nix.
        self.git("add", "-A")
        return self.git("write-tree").strip()

    def remove(self) -> None:
        shutil.rmtree(self.dir, ignore_errors=True)
        self.git("worktree", "prune", cwd=self.repo)
        if os.path.exists(self.built_file):
            os.remove(self.built_file)

    def prepare(self) -> None:
        self.remove()
        os.makedirs(os.path.dirname(self.dir), exist_ok=True)
        # -B resets a branch left from an earlier, unmerged run.
        self.git("worktree", "add", "-B", self.branch, self.dir, "main", cwd=self.repo)

    def finish(self, reply: str) -> dict:
        """Remove the worktree, update the pending list, and report as
        catalyst-cron's WorkflowResult."""
        commits = int(self.git("rev-list", "--count", f"main..{self.branch}", cwd=self.repo))
        self.remove()
        if commits == 0:
            self.git("branch", "-D", self.branch, cwd=self.repo)
        write_pending(self.repo)
        reply = reply.strip().splitlines()[0] if reply.strip() else "no reply"
        if commits == 0:
            return {"notify": False, "summary": reply}
        # The commit subject leads, as it says what changed; the agent's reply
        # follows, for anything to check before merging.
        subject = self.git("log", "-1", "--format=%s", self.branch, cwd=self.repo).strip()
        return {"notify": True, "summary": "\n".join(
            [f"{subject} (branch {self.branch})", reply, "", *review_steps(self.branch)])}

    def tools(self, machine: str) -> list:
        t = self

        @tool
        def read_file(path: str) -> str:
            """Return a file of the repo.

            Args:
                path: Path relative to the repo root, e.g. overlays/claude-code.nix.
            """
            with open(t.path(path), errors="replace") as f:
                return f.read(MAX_OUTPUT)

        @tool
        def edit_file(path: str, old: str, new: str) -> str:
            """Replace the single occurrence of old with new in a repo file.

            Args:
                path: Path relative to the repo root.
                old: Exact text to replace. It must occur exactly once.
                new: Text to put in its place.
            """
            p = t.path(path)
            with open(p) as f:
                s = f.read()
            if (n := s.count(old)) != 1:
                raise ValueError(f"old text occurs {n} times, it must occur once")
            with open(p, "w") as f:
                f.write(s.replace(old, new))
            return "edited"

        @tool
        def fetch(url: str) -> str:
            """HTTP GET a URL and return the start of the body, e.g. a registry's latest version or release notes.

            Args:
                url: An http or https URL.
            """
            if not url.startswith(("https://", "http://")):
                raise ValueError("only http and https URLs")
            r = requests.get(url, timeout=30, headers={"User-Agent": "catalyst-agents"})
            return f"HTTP {r.status_code}\n{r.text[:MAX_OUTPUT]}"

        @tool
        def prefetch(url: str, unpack: bool) -> str:
            """Download a URL into the nix store and return its SRI sha256 hash.

            Args:
                url: URL of the source.
                unpack: True for a hash of the unpacked archive (fetchzip, fetchFromGitHub), False for the file itself (fetchurl).
            """
            out = run(["nix", "store", "prefetch-file", "--json", *(["--unpack"] if unpack else []), url], timeout=900)
            return json.loads(out)["hash"]

        @tool
        def build(attr: str = "") -> str:
            """Build part of this machine's NixOS configuration from the repo, to check the edits.

            Args:
                attr: Attribute under the machine's nixosConfiguration, e.g. pkgs.claude-code. Empty builds the whole system.
            """
            if not ATTR.match(attr):
                raise ValueError(f"invalid attribute {attr!r}")
            tree = t.tree_id()
            run(["nix", "build", "--no-link", "-L",
                 f"{t.dir}#nixosConfigurations.{machine}.{attr or 'config.system.build.toplevel'}"],
                timeout=4 * 3600)
            with open(t.built_file, "w") as f:
                f.write(tree)
            return "build passed"

        @tool
        def flake_update(inputs: list[str]) -> str:
            """Update flake.lock, then return which files changed.

            Args:
                inputs: Names of the flake inputs to update. Empty updates all of them.
            """
            run(["nix", "flake", "update", *inputs], cwd=t.dir, timeout=900)
            return t.git("diff", "--stat") or "no change"

        @tool
        def diff() -> str:
            """Return the uncommitted changes in the repo, as git diff shows them."""
            t.tree_id()
            return t.git("diff", "--cached")[:MAX_OUTPUT] or "no change"

        @tool
        def commit(message: str) -> str:
            """Commit all changes on the branch. Only works once the current content has built.

            Args:
                message: Commit message. First line '<path without .nix>: update <old> -> <new>'.
            """
            built = open(t.built_file).read() if os.path.exists(t.built_file) else ""
            if t.tree_id() != built:
                raise ValueError("the current content has not been built; run build first")
            t.git("commit", "-s", "-m", message)
            return t.git("rev-parse", "--short", "HEAD").strip()

        @tool
        def search(pattern: str) -> str:
            """Find lines in the repo's tracked files that match a regular expression, as path:line:text.

            Args:
                pattern: Extended regular expression, e.g. docker or 'virtualisation\\.docker'.
            """
            p = subprocess.run(["git", "grep", "-n", "-I", "-E", "-e", pattern],
                               cwd=t.dir, capture_output=True, text=True, timeout=60)
            if p.returncode == 1:
                return "no matches"
            if p.returncode != 0:
                raise RuntimeError(p.stderr[-MAX_OUTPUT:])
            return p.stdout[:MAX_OUTPUT]

        return [read_file, search, edit_file, fetch, prefetch, build, flake_update, diff, commit]


def register(runtime: wf.WorkflowRuntime, llm, cfg: dict) -> list[DurableAgent]:
    """Register the bump workflow on runtime, and return an agent per target."""
    trees: dict[str, Tree] = {}
    agents: dict[str, DurableAgent] = {}
    for target, instructions in cfg["bump"].items():
        trees[target] = Tree(cfg["repo"], target)
        agents[target] = DurableAgent(
            name=f"bump-{target}",
            role="Keeps a pinned package up to date",
            goal=f"Bump {target} to its latest release on a branch, with a commit that builds.",
            instructions=INSTRUCTIONS + instructions.strip().splitlines(),
            llm=llm,
            tools=trees[target].tools(cfg["machine"]),
            execution=AgentExecutionConfig(
                # A real bump takes about 6 turns. More than 15 means it is
                # stuck, and every turn resends the whole conversation.
                max_iterations=15,
                # Edits and builds must not race each other.
                tool_execution_mode=ToolExecutionMode.SEQUENTIAL,
            ),
            mcp=AgentMCPConfig(enabled=False),
        )

    def prepare(ctx: wf.WorkflowActivityContext, target: str) -> None:
        trees[target].prepare()

    def finish(ctx: wf.WorkflowActivityContext, inp: dict) -> dict:
        return trees[inp["target"]].finish(inp["reply"])

    def bump(ctx: wf.DaprWorkflowContext, target: str):
        if target not in trees:
            raise ValueError(f"no bump target {target!r}")
        yield ctx.call_activity(prepare, input=target)
        try:
            out = yield ctx.call_child_workflow(
                agents[target].agent_workflow_name,
                input={"task": f"Check {target} for a newer release, and bump it if there is one."},
                instance_id=f"{ctx.instance_id}-agent",
            )
        except Exception:
            # Clean up, then fail the run so catalyst-cron reports why.
            yield ctx.call_activity(finish, input={"target": target, "reply": ""})
            raise
        return (yield ctx.call_activity(
            finish, input={"target": target, "reply": (out or {}).get("content", "")}
        ))

    # Versioned as catalyst-cron's workflows are: callers start the canonical
    # "bump", and a change gets a new version, keeping the old registered while
    # instances still use it. Activities carry their version in their name.
    runtime.register_versioned_workflow(bump, name="bump", version_name="bumpV1", is_latest=True)
    runtime.register_activity(prepare, name="bump.prepareV1")
    runtime.register_activity(finish, name="bump.finishV1")
    return list(agents.values())
