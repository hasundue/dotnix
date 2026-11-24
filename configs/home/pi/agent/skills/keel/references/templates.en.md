# Spec template (English)

One `SPEC.md` sits at the root of the working branch or worktree. The
headings are load-bearing; the prose under them is not. Keep it short -- a spec
nobody rereads is not a gate.

An English session drafts `SPEC.md` directly. A Japanese session drafts
`SPEC.ja.md`; approval translates it to `SPEC.en.md`, checks it, and promotes
it to `SPEC.md`. Drafts and candidates are not committed. When
`SPEC.context.md` exists, commit it with `SPEC.md` and delete both before the
merge.

Frontmatter keys stay English. `created` is the creation date; `status` is
one of `draft`, `agreed`, `done`, `blocked`; `session_lang` is the
conversation's language code; `translated` is the date the spec became
English and stays empty for one written in English from the start. Leave a
field empty until it has a value, and do not carry this legend into the spec.
There is no `branch:` field and no merge metadata.

## The template

```markdown
---
created: <YYYY-MM-DD>
status: draft
session_lang: en
translated:
---

# <Short title>

## Current behavior

<Paths a cold executor reads first, and what they do today. Update these paths
when they change.>
<Only when this grows long, move the paths into `SPEC.context.md` in the
worktree and link that file from the end of this section. Commit
`SPEC.context.md` with `SPEC.md` and delete both before merging.>

## Design

<One line per decision that constrains implementation, with its reason. When a
non-obvious judgment needs background, link the research note at
`~/vault/research/<project>/<subject>.md`; do not copy the background here.
No Decisions or Log section.>

## Out of scope

- <What is explicitly not being built.>

## Acceptance criteria

<Write each condition as a plain `-` item. Hang its verification methods
beneath it as tab-indented `- [ ]` lines: a command, or a manual step with the
expected observation. A condition ending in the user's judgment states what to
decide, never how to reply.>

- <observable outcome>
    - [ ] <command, or manual step with expected observation>

## Stop conditions

<Task-specific limits and conditions only. Omit this section when there are
none. The common conditions -- the same failure twice, work outside the spec,
a trade-off needing a human decision -- live in the sail skill.>

## Blocker

<Add only when work stops: what was tried, what happened, the likely cause, and
the options.>
```

## Language and promotion

The Japanese-to-English heading map and the translation procedure live in
`task-note-lifecycle.md` in this directory. Writing an English spec needs
only this template. From approval on, the spec is English for life, including
blockers and any scope changes written into it.

## Checklist rules

- `- [ ]` is a verification method under a condition, not the condition.
- `- [x] <method> -- <command and result>` records what proves it. Always
  record the evidence.
- A check that failed or could not run stays unticked, with `unmet: <reason>`.
- `## Out of scope` uses plain `-` items, so `[ ]` keeps a single meaning.
- Ticking is not renegotiation. Changing the text of a condition needs a fresh
  confirmation.
- Do not label the method lines; that keeps the count of conditions separate
  from the count of checks.

## Filled example (compact)

```markdown
---
created: 2025-11-30
status: draft
session_lang: en
translated:
---

# Expire sessions on idle, not on a fixed clock

## Current behavior

`src/auth/session.ts` sets `expiresAt = issuedAt + 24h` at login and never
touches it again. `tests/auth/session.test.ts` asserts the 24h value today.

## Design

- Slide `expiresAt` forward on each authenticated request, leaving the
  absolute cap alone -- the cap is a compliance requirement.
- Update the test to distinguish idle and absolute expiry.

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
