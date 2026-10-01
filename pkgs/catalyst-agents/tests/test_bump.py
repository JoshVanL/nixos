"""Checks the bump worktree lifecycle against a throwaway repo.

Run with the package's python: python tests/test_bump.py
"""

import os
import subprocess
import tempfile

tmp = tempfile.mkdtemp()
os.environ["STATE_DIRECTORY"] = os.path.join(tmp, "state")

from catalyst_agents import bump  # noqa: E402


def git(*args: str, cwd: str) -> str:
    return subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True).stdout


repo = os.path.join(tmp, "repo")
os.makedirs(repo)
git("init", "-q", "-b", "main", cwd=repo)
git("config", "user.email", "t@example.com", cwd=repo)
git("config", "user.name", "t", cwd=repo)
with open(os.path.join(repo, "pin.nix"), "w") as f:
    f.write('version = "1.0";\n')
git("add", ".", cwd=repo)
git("commit", "-q", "-m", "init", cwd=repo)

t = bump.Tree(repo, "pkg")
tools = {x.name: x for x in t.tools("m")}

# No commit leaves main alone and removes the branch and worktree.
t.prepare()
assert t.finish("up to date at 1.0") == {"notify": False, "summary": "up to date at 1.0"}
assert not os.path.exists(t.dir)
assert "bump/pkg" not in git("branch", cwd=repo)

t.prepare()
assert tools["read_file"].run(path="pin.nix") == 'version = "1.0";\n'
tools["edit_file"].run(path="pin.nix", old="1.0", new="2.0")
try:
    tools["read_file"].run(path="../repo/pin.nix")
    raise AssertionError("read outside the worktree")
except Exception as e:
    assert "outside the repo" in str(e), e

# Commit refuses content that has not built.
try:
    tools["commit"].run(message="pin: update 1.0 -> 2.0")
    raise AssertionError("committed unbuilt content")
except Exception as e:
    assert "not been built" in str(e), e

# Stand in for a passing build: record the tree id as build does.
with open(t.built_file, "w") as f:
    f.write(t.tree_id())
tools["commit"].run(message="pin: update 1.0 -> 2.0")
assert t.finish("pkg 1.0 -> 2.0") == {"notify": True, "summary": "pkg 1.0 -> 2.0 (branch bump/pkg)"}
assert git("log", "-1", "--format=%s", "bump/pkg", cwd=repo).strip() == "pin: update 1.0 -> 2.0"
assert git("log", "-1", "--format=%s", "main", cwd=repo).strip() == "init"
assert not os.path.exists(t.dir)

print("ok")
