if [ -z "${1:-}" ]; then
  name=$(head -c 6 /dev/urandom | basenc --base32hex | tr '[:upper:]' '[:lower:]' | tr -d '=')
else
  name="$1"
  shift
fi

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
    echo ">> git clone --no-single-branch --depth 1 https://github.com/${repo} $repodir" >&2
    git clone --no-single-branch --depth 1 "https://github.com/${repo}" "$repodir"

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
      "Bash(git *)",
      "Bash(gh *)",
      "Bash(nix *)",
      "Bash(make *)",
      "Bash(go *)",
      "Bash(cargo *)",
      "Bash(rustc *)",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(node *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(grep *)",
      "Bash(rg *)",
      "Bash(ls *)",
      "Bash(ls)",
      "Bash(find *)",
      "Bash(find)",
      "Bash(head *)",
      "Bash(head)",
      "Bash(tail *)",
      "Bash(tail)",
      "Bash(protoc-gen-go)",
      "Bash(protoc-gen-go *)",
      "Edit",
      "Write",
      "WebSearch",
      "WebFetch"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(git push)",
      "Bash(gh pr create *)",
      "Bash(gh pr merge *)",
      "Bash(gh release *)",
      "Bash(gh repo create *)",
      "Bash(gh issue create *)"
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

## Go

- Run `golangci-lint run ./...` when editing Go files to catch lint issues early.
- Do not over-comment code. Only add comments where the logic is not self-evident.
- Never use m-dashes (--) in comments or strings. Use hyphens (-) or reword.

## Dapr

When working on Dapr repositories:

- Integration tests: `go test -v --race --tags integration ./tests/integration/. --focus <TestNameRegex>`
  Use `--focus` to target specific test names rather than running the full suite.
- Run integration tests when your changes need verification beyond unit tests.
- Custom compile Dapr binaries (daprd, placement, scheduler, sentry, operator, injector)
  for integration tests using a unique output path so parallel runs do not interfere
  with each other. For example:
  `go build -tags allcomponents -o /tmp/daprd-<unique> ./cmd/daprd`
  Then point the test to that binary via the appropriate env var or test flag.
CLAUDEMD
else
  echo ">> Skipping CLAUDE.md: already exists" >&2
fi

# Print the directory path for the shell function wrapper
echo "$dir"
