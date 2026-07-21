---
name: actionable-pr-review
description: Review an open-source pull request (GitHub PR URL/number, branch, or diff) and surface ONLY findings the author must act on - verified against the real code, refuting plausible-but-wrong ones. Use when asked to review a contribution, review a PR, or "should this merge". Produces ranked findings plus copyable GitHub review comments. Never posts to GitHub.
---

# Actionable PR review

Review a contribution and report **only what the author has to change**. The
default failure mode of code review is noise: confirmatory "looks good" notes,
style preferences, optional simplifications, and plausible-but-unverified bugs.
This skill exists to suppress all of that and leave a short list of must-fix
findings, each one verified against the actual code.

## The bar: "must act on"

Surface a finding ONLY if it is one of these, with a concrete trigger:

- **Correctness bug / regression** - name the inputs/state that produce the
  wrong output, crash, hang, leak, or race.
- **Behavioral-contract break** - especially in refactors: a changed error
  code / HTTP status / gRPC code / user-visible message, a changed return
  shape, a new precondition that breaks a caller.
- **CI failure** - anything that fails the project's gates: lint (import
  ordering, gofmt/goimports), a compile error (unused or missing import after
  add/remove, undefined symbol), a broken or unregistered test.
- **Missing wiring** - a new test file not registered into the suite, a new
  flag not defaulted, a resource not gated where it must be.

Do NOT surface (unless the user explicitly asks for a broader/thorough review):
style and naming preferences, optional simplifications, redundant-but-harmless
defensive code, "nice to have" extra tests, or confirmatory "this is fine"
notes. If nothing survives the bar, say so plainly: **"nothing to do."** An
empty result is a valid and valuable answer.

Rank surviving findings most-severe first. Correctness/regression outranks
CI-failure outranks wiring.

## Verify before reporting; refute hard

Never report a candidate you have not verified against the real code. For each
candidate, actively try to REFUTE it:

- **Trace callers** of every changed function (grep the symbol) - does the new
  precondition/return/error actually reach a caller that mishandles it? If the
  function has no callers, say so (that changes severity).
- **Trace downstream** - does the changed value flow into something that breaks?
  Read the helper/library it calls (e.g. does `WithRawDataBytes` panic only
  when replay is enabled? is this response replay-enabled?).
- **Check the guard** - is the scary path actually reachable, or guarded by a
  precondition upstream (an early `return` on empty, an EOF that the runtime
  reclaims, a limit reader that errors instead of truncating)?
- **For removed code** - name the invariant it enforced, then find where the new
  code re-establishes it.

Only keep a finding when you can state concrete inputs/state -> wrong outcome.
If investigation shows a scary-looking change is actually safe, drop it - but
when the change *looks* dangerous, a one-line "investigated X, it's safe
because Y" reassures the maintainer and shows the path was checked. Do not pad
with these.

## Gather the target

The diff is the review scope; the checkout is for context. Prefer `gh` over any
local `git diff`.

1. `gh pr view <url|number> --json title,body,author,baseRefName,headRefName,state,additions,deletions,changedFiles,labels`
2. `gh pr diff <url|number>` for the unified diff.
3. Fetch the head so you can read full files, trace callers, and read
   downstream/library code:
   `git fetch origin pull/<N>/head` then read via `git show FETCH_HEAD:<path>`.
   (Re-fetch per PR - `FETCH_HEAD` is overwritten. Confirm you're reading the
   right head: the working tree may be a different branch or PR.)

When the target is a branch or a raw diff instead of a PR, adapt: use the diff
as scope and read files from the checkout if it matches, else fetch by ref.

## Refactor checklist

Migrations/refactors ("standardize X", "replace Y with Z") are where silent
regressions hide. Check, in order:

1. **Parity** - does the new path produce byte-identical observable behavior?
   Compare old vs new: message text, status/code constants, error reason
   strings. A mismatch clients key on is a must-fix.
2. **Compile** - after adding/removing an import, is it actually used / still
   used? Grep the file for remaining references. Unused import and undefined
   symbol both break the build.
3. **Lint** - import ordering (goimports/gci sorts groups alphabetically),
   gofmt. Confirm the project enforces it (`.golangci.yml`) before calling it a
   failure.
4. **Test wiring** - new `*_test`/suite files imported into the parent
   registration? Trace the `import _` chain.
5. **Dead assertions** - does a preserved type assertion / `errors.As` still
   match the new error type, or does the refactor route a different type into it?

## Output

First, a 2-3 sentence plain overview of what the PR does. Then:

**Findings** - ranked, each as: `file:line - one-sentence summary (concrete
failure scenario)`. Or the single line "Nothing to do." when the set is empty.

**Copyable GitHub comments** - when the user wants comments to post, give each
in a **4-backtick fenced block** so any inner ```` ```suggestion ```` fence
survives copy-paste, with the location stated above the block:

- Anchor to an exact `file`, `line` (or line range for a multi-line
  suggestion). Line numbers are the PR-head file's numbers.
- Include a ```` ```suggestion ```` block whenever a concrete edit applies;
  for a multi-line reorder/rewrite, cover the whole contiguous range.
- Keep the prose to why-it-must-change, briefly.

Only produce comments that meet the "must act on" bar. Do not emit a top-level
"LGTM + rationale" comment or "optional nit" comments dressed as review
comments - if the user wants reassurance, put it in your chat reply, not in a
postable comment.

**Merge judgment** - when asked "safe to merge?" / "ok as-is?", answer directly
and separate *blocks merge* (correctness/CI/compile) from *leaves debt*
(unfixed twin, missing tests, undocumented flag). If the fix targets unused/dead
code, or safety hinges on an assumption ("if it's not used"), state that
assumption as the load-bearing caveat.

## Hard constraints

- **Never** post to GitHub: no PR/issue comments, reviews, approvals, merges,
  or `gh` write calls. You draft; the user posts.
- Honor the repo's `CLAUDE.md` and the user's global rules (e.g. no em dashes in
  any output).
- Scale effort to the diff: for a small diff, trace manually and exhaustively;
  for a large one, consider parallel finder agents by angle (line-by-line,
  removed-behavior, cross-file/callers, refactor-parity), then verify each
  candidate before it survives.
