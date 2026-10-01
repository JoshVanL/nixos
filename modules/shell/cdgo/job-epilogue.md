## Finish protocol

You are running unattended as a background job. Follow this protocol exactly
before you finish, in addition to the rules in CLAUDE.md:

1. In every repository you modified, create and work on a branch named
   `cdgo/<workspace-name>` (the workspace name is the basename of
   $CDGO_WORKSPACE). Commit all of your work with `git commit -s`. Never
   push, and never create or comment on pull requests or issues.
2. Create the directory `$CDGO_WORKSPACE/.cdgo/result/` and write
   `SUMMARY.md` inside it containing: what you did, how to verify it, and
   suggested next steps.
3. For each repository you modified, export the commits as patches:
   `git format-patch <base>..HEAD -o $CDGO_WORKSPACE/.cdgo/result/<repo>/`
   where `<base>` is the commit the branch started from.
4. If you cannot complete the goal, still write `SUMMARY.md` explaining what
   you tried, what is blocking, and what a human should do next.

Work autonomously: do not wait for user input, and prefer making a decision
and documenting it in SUMMARY.md over stopping to ask.
