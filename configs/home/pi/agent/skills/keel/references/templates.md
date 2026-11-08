# Template

One note per task. The headings are load-bearing; the prose under them is not.
Keep it short -- a note nobody rereads is not a spec.

## The template

`status` is one of `draft`, `agreed`, `done`, `blocked`. `confirmed` takes the
date the user confirmed; a note that is still a draft keeps it empty, which is a
normal state, not a defect. `pr` and `merge_commit` are filled in after the
merge. Leave a field empty until it has a value, and do not carry this legend
into the note.

```markdown
---
created: <YYYY-MM-DD>
status: draft
branch: <branch the task runs on>
confirmed:
pr:
merge_commit:
---

# <Short title>

## Problem

<The problem, as plainly as possible. No solution, no implementation.>

## Who feels it, and when

<Who hits this, at what moment, and what it costs them.>

## What was tried

<Prior attempts and why they were not enough. Omit if none.>

## What "fixed" looks like -- in the user's words

<A real quote, or leave this section out. A paraphrase belongs under Design.>

> "<verbatim quote>"

## Current behavior

<What a cold reader needs: paths, current behaviour, prior decisions and why.>

## Design

<The agreement. One `###` per area: storage, format, discovery, whatever this
task actually touches.>

## Out of scope

- <What we are explicitly not building, and why, if non-obvious.>

## Acceptance criteria

- [ ] <observable outcome>
      verify: `<command>` / <manual step with expected observation>
- [ ] <observable outcome>
      verify: `<command>`

## Stop conditions

- The same failure twice -> write the cause under `## Blocker`, stop
- Needs to touch something outside this spec -> stop
- A trade-off that needs a human decision -> stop
- <Per-task limit: attempts, time, files.>

## Decisions

- <date> -- <decision> -- <reason>

## Confirmed

- <date> -- user: "<their words>"

## Log

<Append-only. Research, dead ends, open questions, sketches.>
```

## Checklist rules

- `- [ ]` -- criterion not yet verified.
- `- [x]` -- verified, with what proves it recorded with it: the command and its
  result, or what was observed and where.
- Unmet stays unticked, marked `unmet: <reason>`.
- `## Out of scope` uses plain `-` items, so `[ ]` keeps a single meaning.
- Ticking is not renegotiation. Changing the text of a criterion is, and needs a
  fresh confirmation.
- `status: done` once every criterion is ticked or reported unmet and the user
  has said the task is closed. Do not ask whether to close.

## Filled example (compact)

```markdown
---
created: 2025-11-30
status: agreed
branch: idle-timeout
confirmed: 2025-11-30
---

# Expire sessions on idle, not on a fixed clock

## Problem

Users are logged out mid-task after 24 hours, no matter how active they were.

## What "fixed" looks like

> "A session should end because I stopped, not because the clock ran out."

## Current behavior

`src/auth/session.ts` sets `expiresAt = issuedAt + 24h` at login and never
touches it again. `tests/auth/session.test.ts` asserts the 24h value today.

## Design

Slide `expiresAt` forward on each authenticated request, leaving the absolute
cap alone. Update the test to distinguish idle and absolute expiry.

## Out of scope

- Remember-me, sliding refresh tokens, per-role timeouts
- Migrating existing sessions (they expire on the old rule)

## Acceptance criteria

- [ ] A request 31 minutes after the last one is rejected with 401
      verify: `pnpm test tests/auth/session.test.ts -t idle`
- [ ] A request 29 minutes after the last one succeeds and resets the clock
      verify: same test file, `-t active`
- [ ] The 24h absolute cap still applies
      verify: `-t absolute`

## Stop conditions

- Same failure twice -> stop and report
- Touching anything under `src/billing/` -> stop

## Decisions

- 2025-11-30 -- idle timeout only, no absolute cap change -- smaller diff, and
  the cap is a compliance requirement

## Confirmed

- 2025-11-30 -- user: "go that way"
```
