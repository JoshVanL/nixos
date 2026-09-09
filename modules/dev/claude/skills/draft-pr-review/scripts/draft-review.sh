#!/usr/bin/env bash
# Create a PENDING (draft) GitHub pull request review from a directory of comment files.
#
# Usage:
#   draft-review.sh <owner/repo> <pr-number> <comments-dir>
#
# comments-dir layout:
#   body.md      review summary in markdown (optional)
#   *.md         one inline comment per file, processed in sorted filename order:
#                  line 1:  path/in/repo.go:LINE   (LINE on the new side of the diff)
#                  line 2:  blank
#                  rest:    comment body in GitHub markdown
#
# Environment:
#   DRY_RUN=1    print the review JSON and exit without touching GitHub
#
# The request never includes an "event", so GitHub stores the review as PENDING.
# It is visible only to the authenticated user until they submit it on the website.
set -euo pipefail

usage() { sed -n '2,17p' "$0" >&2; exit 2; }
[[ $# -eq 3 ]] || usage

REPO=$1
PR=$2
DIR=$3

for tool in gh jq awk; do
  command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done
[[ -d "$DIR" ]] || { echo "comments dir not found: $DIR" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SHA=$(gh pr view "$PR" --repo "$REPO" --json headRefOid -q .headRefOid)

# Every path:line on the new side of the PR diff, one per line.
gh pr diff "$PR" --repo "$REPO" | awk '
  /^\+\+\+ /  { f = substr($0, 7); if (f == "/dev/null") f = ""; next }
  /^--- /     { next }
  /^@@ /      { match($0, /\+[0-9]+/); n = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
  /^\+/       { if (f != "") print f ":" n; n++; next }
  /^ /        { if (f != "") print f ":" n; n++; next }
  /^$/        { if (f != "") print f ":" n; n++; next }
' | sort -u > "$TMP/diff-lines"

COMMENTS="$TMP/comments.json"
echo '[]' > "$COMMENTS"
bad=0
count=0

for f in "$DIR"/*.md; do
  [[ "$(basename "$f")" == "body.md" ]] && continue
  target=$(head -n1 "$f")
  path=${target%:*}
  line=${target##*:}
  if [[ -z "$path" || ! "$line" =~ ^[0-9]+$ ]]; then
    echo "$(basename "$f"): first line must be path:LINE, got '$target'" >&2
    bad=1; continue
  fi
  if ! grep -qxF "$path:$line" "$TMP/diff-lines"; then
    echo "$(basename "$f"): $path:$line is not on the new side of the PR diff" >&2
    bad=1; continue
  fi
  tail -n +2 "$f" | sed '1{/^$/d;}' > "$TMP/body.txt"
  jq --arg p "$path" --argjson l "$line" --rawfile b "$TMP/body.txt" \
    '. + [{path:$p, line:$l, side:"RIGHT", body:$b}]' "$COMMENTS" > "$COMMENTS.new"
  mv "$COMMENTS.new" "$COMMENTS"
  count=$((count + 1))
done

[[ $bad -eq 0 ]] || { echo "fix the targets above; nothing was created" >&2; exit 1; }
[[ $count -gt 0 ]] || { echo "no comment files found in $DIR" >&2; exit 1; }

if [[ -f "$DIR/body.md" ]]; then
  jq -n --arg sha "$SHA" --rawfile body "$DIR/body.md" --slurpfile c "$COMMENTS" \
    '{commit_id:$sha, body:$body, comments:$c[0]}' > "$TMP/review.json"
else
  jq -n --arg sha "$SHA" --slurpfile c "$COMMENTS" \
    '{commit_id:$sha, comments:$c[0]}' > "$TMP/review.json"
fi

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  cat "$TMP/review.json"
  echo "dry run: $count comments validated against $SHA; nothing created" >&2
  exit 0
fi

pending=$(gh api "repos/$REPO/pulls/$PR/reviews" --jq '[.[] | select(.state=="PENDING")] | length')
if [[ "$pending" != "0" ]]; then
  cat >&2 <<EOF
You already have a pending review on this PR. GitHub allows one draft per user.
Finish or discard it on the website, or delete it with:
  gh api repos/$REPO/pulls/$PR/reviews --jq '.[] | select(.state=="PENDING") | .id'
  gh api -X DELETE repos/$REPO/pulls/$PR/reviews/<id>
EOF
  exit 1
fi

gh api -X POST "repos/$REPO/pulls/$PR/reviews" --input "$TMP/review.json" \
  --jq '"draft review \(.id) created (state: \(.state))"'
echo "$count inline comments staged. Inspect at https://github.com/$REPO/pull/$PR/files and press 'Finish your review' to submit." >&2
