# Spec template (English)

One `SPEC.md` sits at the root of a linked worktree. The headings are
load-bearing; the prose under them is not. Keep it short -- a spec nobody
rereads is not a gate.

An English session drafts `SPEC.md` directly. A Japanese session drafts
`SPEC.ja.md`; approval follows `spec-lifecycle.md`. Drafts and candidates are not
committed.

Frontmatter keys stay English. `status` is one of `draft`, `agreed`, `blocked`,
`stale`; `stale` means a promoted spec's work is no longer being pursued. A
dropped draft is deleted uncommitted; it never becomes `stale`. `session_lang`
is the conversation's language code. `## Blocker` belongs only to `blocked`. Do
not carry this legend into the spec.

## The template

```markdown
---
status: draft
session_lang: en
---

# <Short title>

## Problem

<Why this change is needed, in two to four lines. No solution.>

## Design

<One line per decision that constrains implementation, with its reason. Name the
paths a decision depends on in its own line. No Decisions or Log section.>

## Out of scope

- <What is explicitly not being built.>

## Acceptance criteria

<Write each condition as a plain `-` item. Hang its verification methods beneath
it as two-space-indented `- [ ]` lines: a command, or a manual step with the expected
observation. A condition ending in the user's judgment states what to decide,
never how to reply.>

- <observable outcome>
  - [ ] <command, or manual step with expected observation>

## Stop conditions

<Task-specific limits and conditions only. Omit the section when there are none.
The common conditions live in the sail skill.>
```

Add `## Blocker` only while `status: blocked`, outside the draft:

```markdown
## Blocker

<The context needed to resume -- for example, what was tried, what happened,
the likely cause, and the options.>
```

When the status leaves `blocked`, move that context into the commit body and
remove the section.

## Language and promotion

The Japanese-to-English heading map and the translation procedure live in
`spec-lifecycle.md` in this directory. Writing an English spec needs only this
template. From approval on, the spec is English for life, including blockers and
any scope changes written into it.

## Checklist rules

- `- [ ]` is a verification method under a condition, not the condition.
- A method is recorded as `- [x] <method> -- <command and result>`. A failed or
  unrun one stays unticked, with `unmet: <reason>`.
- `## Out of scope` uses plain `-` items, so `[ ]` keeps a single meaning.
- Ticking is not renegotiation. Changing the text of a condition needs a fresh
  confirmation.
- Do not label the method lines; that keeps the count of conditions separate
  from the count of checks.

## Filled example (compact)

```markdown
---
status: draft
session_lang: en
---

# Expire sessions on idle, not on a fixed clock

## Problem

Users are logged out in the middle of a task after 24 hours, however active they
were. Sessions should end when the user stops working, not when a clock runs out.

## Design

- Slide `expiresAt` forward on each authenticated request and leave the absolute
  cap alone -- the cap is a compliance requirement.
- `src/auth/session.ts` sets `expiresAt = issuedAt + 24h` at login and never
  touches it again. `tests/auth/session.test.ts` asserts the 24h value; split it
  into idle and absolute cases.

## Out of scope

- Remember-me, sliding refresh tokens, per-role timeouts
- Migrating existing sessions (they expire on the old rule)

## Acceptance criteria

- A request 31 minutes after the last one is rejected with 401
  - [ ] `pnpm test tests/auth/session.test.ts -t idle`
- A request 29 minutes after the last one succeeds and resets the clock
  - [ ] same test file, `-t active`
- The 24h absolute cap still applies
  - [ ] same test file, `-t absolute`

## Stop conditions

- Touching anything under `src/billing/` -> stop
```
