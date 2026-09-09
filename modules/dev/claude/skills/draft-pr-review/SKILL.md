---
name: draft-pr-review
description: Turn code-review findings for a GitHub pull request into a PENDING (draft) review with inline comments, created via the gh CLI so the user can inspect, edit, and submit it on the GitHub website. Nothing becomes visible to the PR author until the user presses "Finish your review". Use after /code-review or actionable-pr-review when the user wants the findings staged on GitHub, or asks for "a review I can look at before submitting".
---

# Draft PR review

Stage review findings on a GitHub pull request as a pending review. A pending
review is private to the reviewer: GitHub shows it only to them on the PR's
"Files changed" tab, where they can edit or delete individual comments and then
choose Comment, Approve, or Request changes themselves. This skill never
submits a review and never passes an `event` to the API.

## Inputs

- A PR URL or `owner/repo` plus number.
- Findings. Use the ones already in the conversation from `/code-review` or
  `actionable-pr-review`. If there are none, run one of those first; this skill
  only formats and stages, it does not review.

## Steps

1. **Resolve the head commit.** Line numbers must be taken against the PR head:
   `gh pr view <n> --repo <owner/repo> --json headRefOid -q .headRefOid`.
   If the findings were produced against an older commit and the branch has
   been pushed since, re-check every line number against the current diff.

2. **Write the comments directory** in the scratchpad, e.g.
   `<scratchpad>/pr<n>-review/`:

   - `body.md`: the review summary, two to four sentences. Thank the author,
     name the one or two things that block merge, mention the biggest
     optional suggestion, end with "Details inline." Optional; omit for no
     summary.
   - One file per inline comment, named `NN-<slug>.md` with `NN` ordering by
     severity (01 = most severe). Format:

     ```
     path/relative/to/repo.go:LINE

     Comment body in GitHub markdown.
     ```

     First line is `path:line` on the RIGHT (new) side of the diff. Second
     line blank. Everything after is the body.

3. **Write each body** so the author can act without re-deriving anything:
   - What is wrong, with the concrete trigger (inputs, state, sequence).
   - Evidence: the file:line chain you followed, a test you ran, a measurement.
   - A specific suggestion, with a code block when it is short enough.
   - One finding per comment. Two comments on the same line are fine and show
     as separate threads.
   - No em dashes. Code identifiers in backticks. Snippets in fenced blocks.

4. **Dry run** to validate:
   `DRY_RUN=1 scripts/draft-review.sh <owner/repo> <n> <comments-dir>`
   The script checks each `path:line` is present on the new side of the PR
   diff. GitHub rejects the whole review with a 422 if any line is outside the
   diff, so fix every reported target before continuing. Move a comment to the
   nearest changed line, or fold it into the summary body, if its line is not
   in the diff.

5. **Create the draft**:
   `scripts/draft-review.sh <owner/repo> <n> <comments-dir>`
   The script refuses to run if the user already has a pending review on the
   PR (GitHub allows one per user) and prints how to delete it.

   If the workspace rules forbid any write to GitHub from Claude, do not run
   this step. Give the user the exact command instead and stop.

6. **Report.** Tell the user: the review is a draft only they can see, the
   number of inline comments, the URL
   `https://github.com/<owner/repo>/pull/<n>/files`, and that they submit it
   with "Finish your review". Do not restate the findings.

## Facts about the GitHub API this relies on

- `POST /repos/{owner}/{repo}/pulls/{n}/reviews` without `event` creates a
  review in state `PENDING`.
- Inline comments use `path`, `line`, `side: "RIGHT"`, and `body`. Every
  `line` must appear in the PR diff for that file.
- One pending review per user per PR. List with
  `gh api repos/<owner/repo>/pulls/<n>/reviews --jq '.[] | select(.state=="PENDING") | .id'`
  and delete with `gh api -X DELETE repos/<owner/repo>/pulls/<n>/reviews/<id>`.
- The summary body is prefilled in the "Finish your review" box for editing.
