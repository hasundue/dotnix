# Template

One note per task. The headings are load-bearing; the prose under them is not.
Keep it short -- a note nobody rereads is not a spec.

## The template

`status` is one of `draft`, `agreed`, `done`, `blocked`. `session_lang` is the
language of the conversation as an ISO 639-1 code, so a cold session knows
which tongue to report in. `translated` is the date the note became English; it
stays empty for a note written in English from the start. `pr` and
`merge_commit` are filled in after the merge. Leave a field empty until it has a
value, and do not carry this legend into the note.

```markdown
---
created: <YYYY-MM-DD>
status: draft
session_lang: <ja | en>
translated: <YYYY-MM-DD>
branch: <branch the task runs on>
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

## What "fixed" looks like

<The outcome, restated plainly. Never a quotation of the user: say what they
want and why, in your own sentence. Omit the section if the criteria already
say it.>

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

## Log

<Append-only. Research, dead ends, open questions, sketches.>
```

## Language and filenames

A draft is written in the language of the session; the approved note is always
English. `<note>` is the file name without its extension --
`<YYYY-MM-DD>-<slug>` for a project note.

| File               | Means                                               |
| ------------------ | --------------------------------------------------- |
| `<note>.md`        | the note: an English draft, or any approved note    |
| `<note>.<lang>.md` | a draft in another language, e.g. `<note>.ja.md`    |
| `<note>.en.md`     | the English candidate, only while its check is open |

Approval is the moment of change: translate, check, promote. `<note>.en.md`
becomes `<note>.md`, `translated:` takes the date, and the draft is deleted. The
candidate keeps `status: draft` until then. A paired copy left behind is a note
that will drift. From approval on the body is English for life.

## Translation check

Someone who did not write the translation compares the pair, mechanically.
Inside a code span or a fence is code; everything else is prose, and a heading
of this note is a name that other lines may point at.

- every heading present, in order, with no section merged or dropped
- every acceptance criterion present: same count, same order, same
  `[ ]` / `[x]` / `unmet:` state
- code identical, character for character: commands, paths, identifiers,
  versions, numbers, and the contents of every backtick and fence. A command
  that greps for Japanese labels in the repository stays Japanese.
- prose translated, `verify:` steps written as sentences included. A verify
  that still reads Japanese is an untranslated note, not a faithful copy.
- references resolve: a mention of this note's own heading or criterion moved
  with its target, backticked or not, and no line points at a heading the
  translation renamed. Code that would break because a heading moved is
  reported, not rewritten.
- no quotation of the user anywhere: restatements carry the same content,
  attributed
- the problem still states the same problem -- a translation that reads better
  but says something else is a finding, not an improvement
- the log translated one entry for one; it is evidence, not prose to polish

Anything that fails is fixed before the promotion, not after.

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
session_lang: en
branch: idle-timeout
---

# Expire sessions on idle, not on a fixed clock

## Problem

Users are logged out mid-task after 24 hours, no matter how active they were.

## What "fixed" looks like

Sessions should end because the user stopped working, not because a clock ran
out.

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
```
