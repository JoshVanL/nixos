---
name: claude-account
description: 'List, save, or switch Claude account credential profiles using the cdgo account CLI. Invoke with /claude-account [list|current|save <name>|switch <name>|login <name>].'
disable-model-invocation: true
---

# claude-account

Manage named Claude account profiles. Profiles are stored under
`~/.claude/accounts/<name>/` and swapped into `~/.claude/.credentials.json`
by the `cdgo account` CLI.

## Rules

- Only ever use the `cdgo account` CLI. Never read, edit, copy, or delete
  `~/.claude/.credentials.json`, `~/.claude.json`, or anything under
  `~/.claude/accounts/` directly.
- Never print token values or credential file contents to the user.

## Behavior

- No argument, or "list": run `cdgo account list` and show the result as a
  table (current profile is marked with `*`).
- "current": run `cdgo account current` and report the active profile.
- "save <name>": run `cdgo account save <name>` and report the output.
- "switch <name>": run `cdgo account switch <name>` and report the output.
  Then tell the user: this running session keeps using its in-memory token
  until the next token refresh; new requests and new sessions use the new
  account immediately. Restart claude to apply it immediately.
- "login <name>": do NOT run this one inside the session (it needs an
  interactive login flow). Tell the user to run `cdgo account login <name>`
  in a terminal outside claude.
