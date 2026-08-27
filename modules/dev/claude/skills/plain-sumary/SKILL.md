---
name: plain-summary
description: >
  Write a summary, explanation, or report of work in plain language. Load this
  before writing any summary of what you did or found, any explanation of a
  change or a bug, any PR description, any plan, or any answer to "explain
  this", "summarize this", "what did you change", "what is wrong". Also load it
  when the user says an answer was verbose, confusing, jargon-heavy, or asks
  for it "in simple language" — that means the last answer broke these rules.
---

# Plain summaries

The reader wants to know the outcome of the task (what happened, what you found, what you fixed) and what it means for them (what decisions or actions are needed). They are not interested in the mechanics, or the history of how you get there. If they are, they will ask.

## Order

1. **What is true now** — one sentence. The fix, the finding.
2. **Why** — what supports this. 5 to 10 sentences.
3. **What it means for them** — what to do, what changed, what is still open. 2-5 sentences.

## Length

Answer in under 150 words.

Cut every sentence that does not change what the reader does next.

## Sentences

One idea per sentence. If a sentence has two em-dashes, or a parenthetical
carrying a new fact, split it.

Do not stack modifiers into new compound nouns. "The write-on-change change
breaks 8 tests" is unreadable. Write "8 tests fail when the component writes on
every change."

No bold inside a sentence for emphasis. Bold a heading or nothing.

## Anti-patterns

Ban the following pattern, not just the words:

- **No metaphors** for technical mechanics. Name the file, flag, function, process or value.
- **No coined phrases.** No "say a word and I'll do it". No "X is where Y goes to die".
- **No contrast openers.** Never "the real problem is not X, it's Y", "this is
  less about A than B". Say the thing directly.
- **No hyperbole.** Nothing "collapses", "closes", "unlocks", "is the crux", "have teeth".
- **No invented taxonomy.** Do not introduce categories unless the user used them or the code does.
- **No narrative detours.** Never open with a caveat, a prerequisite, or "first, the thing worth settling". Start with the result/conclusion.
- **No explanation by comparison.** Never explain the outcome in contrast to other alternatives considered (for example "contrary to option 1 this approach"). Summarize alternatives only if asked.
- **No historical account.** Never present the outcome in the context of the session. "I first tried X".

## What to leave out

- Implementation detail the reader did not ask for.
- Alternatives you rejected, unless asked. If asked, put them last.
- Time estimates. Convey size by what is touched and what is blocked.
- Any preamble, and any recap of what you just said.

## Before you send

Read it once as the user. Then check:

- Is the first sentence the answer?
- Would a coined phrase or metaphor survive a search for it in the codebase?
- Can any sentence be cut without losing information?
- Did I explain how it works when I was asked what changed?

If the user replies "simpler", "too verbose", or "no jargon", do not defend the
answer. Rewrite it shorter, and note which rule above you broke.
