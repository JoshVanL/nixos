if [ -z "${1:-}" ]; then
  echo "Usage: cdgo <name> [owner/repo ...]" >&2
  exit 1
fi

name="$1"
shift

dir="$HOME/sandbox/workspace/$name"
echo ">> mkdir -p $dir" >&2
mkdir -p "$dir"

# Expand group names to repos
repos=()
for arg in "$@"; do
  group_repos=$(jq -r --arg g "$arg" '.[$g] // empty | .[]' "$CDGO_GROUPS_FILE")
  if [ -n "$group_repos" ]; then
    echo ">> Expanding group '$arg'" >&2
    while IFS= read -r r; do
      repos+=("$r")
    done <<< "$group_repos"
  else
    repos+=("$arg")
  fi
done

# Clone repos concurrently
pids=()
for repo in "${repos[@]}"; do
  owner="${repo%%/*}"
  reponame="${repo##*/}"
  repodir="$dir/$reponame"

  if [ -d "$repodir" ]; then
    echo ">> Skipping $repo: $repodir already exists" >&2
    continue
  fi

  (
    echo ">> git clone --depth 1 https://github.com/${repo} $repodir" >&2
    git clone --depth 1 "https://github.com/${repo}" "$repodir"

    if [ "$owner" != "joshvanl" ]; then
      echo ">> git -C $repodir remote add fork git@github.com:joshvanl/${reponame}.git" >&2
      git -C "$repodir" remote add fork "git@github.com:joshvanl/${reponame}.git"
    fi
  ) &
  pids+=($!)
done

# Wait for all clones and fail if any failed
failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=1
  fi
done
if [ "$failed" -ne 0 ]; then
  echo ">> Some clones failed" >&2
  exit 1
fi

# Write .claude/settings.json if it doesn't exist
mkdir -p "$dir/.claude"
if [ ! -f "$dir/.claude/settings.json" ]; then
  echo ">> Writing $dir/.claude/settings.json" >&2
  cat > "$dir/.claude/settings.json" << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(nix:*)",
      "Bash(make:*)",
      "Bash(go:*)",
      "Bash(cargo:*)",
      "Bash(rustc:*)",
      "Bash(python:*)",
      "Bash(python3:*)",
      "Bash(node:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(grep:*)",
      "Bash(rg:*)",
      "WebSearch",
      "WebFetch"
    ],
    "deny": [
      "Bash(git push:*)",
      "Bash(git push)",
      "Bash(gh pr create:*)",
      "Bash(gh pr merge:*)",
      "Bash(gh release:*)",
      "Bash(gh repo create:*)",
      "Bash(gh issue create:*)"
    ]
  }
}
SETTINGS
else
  echo ">> Skipping .claude/settings.json: already exists" >&2
fi

# Write CLAUDE.md if it doesn't exist
if [ ! -f "$dir/CLAUDE.md" ]; then
  echo ">> Writing $dir/CLAUDE.md" >&2
  cat > "$dir/CLAUDE.md" << 'CLAUDEMD'
When making git commits, ALWAYS use `git commit -s` (signoff flag).
NEVER push to any remote (origin, fork, or any other).
NEVER create, merge, or comment on pull requests or issues on GitHub.
NEVER create releases or repositories on GitHub.
CLAUDEMD
else
  echo ">> Skipping CLAUDE.md: already exists" >&2
fi

# Print the directory path for the shell function wrapper
echo "$dir"
