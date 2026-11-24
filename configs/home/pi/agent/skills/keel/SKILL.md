---
name: keel
description: >
  Pre-work spec gate for large changes: agree the design and the acceptance
  criteria in a SPEC.md on the working branch, then hand control back before
  implementing. Use at the start of a feature, refactor, migration, or any
  multi-file change whose shape is not yet agreed; when the user says "spec it
  out", "define the criteria", "before we start", "let's plan"; or when you are
  about to guess at requirements.
---

# Keel

Lay the keel before the hull: agree on the design and how it will be checked
where the work will be committed, then hand control back.

Keel is not a mode and not a pipeline. It has four invariants you may not skip
and a toolbox you use at your discretion. As models get better, the toolbox
should be used better; the invariants should shrink, not grow.

## Invariants

1. **Nothing is implemented in the turn that opens a gate: hand control back
   and let the user move first. Do not put the spec to a vote.**
2. **The work is either declared small and gated in conversation, or has one
   `SPEC.md` with a design and acceptance criteria.**
3. **The spec names what is out of scope.**
4. **If scope moves mid-work, it moves in the agreement before anyone acts on
   it.**

Everything else -- how many questions, whether to research first, how the spec
is organized -- is judgment.

## The spec

One `SPEC.md` sits at the root of the working branch or worktree. A worktree
maps one-to-one to a branch, so no `branch:` field tracks the correspondence.
The promoted spec is committed with the work and deleted before the merge.

In a Japanese session the draft is `SPEC.ja.md`; at approval `SPEC.en.md` is
checked and promoted to `SPEC.md`. In an English session `SPEC.md` is the
draft and promotion only updates its metadata. Drafts and candidates are not
committed. When the current-behavior section grows, its paths move into
`SPEC.context.md` in the worktree, which is committed with `SPEC.md` and
deleted before the merge.

Resolve the project from git when the background note needs its location:

```sh
basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
# ~/dotnix.pi-workflow -> dotnix
```

Not in a git repository? Ask for the project; do not guess.

Keel writes no notes into the vault. An old vault note is read only when its
path is passed explicitly, and is never migrated.

## Language and the approval act

Use the template matching the session language:
`references/templates.ja.md` or `references/templates.en.md`. Do not read the
other one just to write a draft. The approval act lives in
`references/task-note-lifecycle.md`, which also maps Japanese headings to
English ones. The parts a gate must hold:

- a Japanese session's draft is `SPEC.ja.md` with `session_lang: ja`; an
  English session's draft is `SPEC.md` with `session_lang: en`; ask before
  inventing another suffix;
- approval translates it once, has someone who did not translate it check the
  pair, then promotes the candidate and deletes the draft;
- from approval on, the spec is English for life, and restates what the user
  wants rather than quoting them.

Keel writes the draft and stops. Approval belongs to whoever the user hands the
work to: sail, or this session if the user approves here. When the user
approves here, run `references/task-note-lifecycle.md` -- translate, check via
skiff, and promote only if the checker concludes that the agreement survived
the translation. When a rule changes, change it there -- sail reads the same
file.

## Finding an existing spec

1. A path the user passed wins, including an explicit path to an old vault
   note; read it, do not migrate it.
2. Otherwise inspect `SPEC.md`, `SPEC.ja.md`, and `SPEC.en.md` at the root
   of the working tree. Treat a `.ja.md` / `.en.md` pair as one spec
   mid-translation.
3. Otherwise ask. Never guess.

A person who names a task in passing has not asked for a second spec on it.

## Branches

Branches are execution's business, not the gate's. Do not cut one on your own
initiative. The spec sits on whatever branch the work is on.

## When to use this

Routing is conservative on purpose: a wrong auto-invocation is more annoying
than a missed one, because `/skill:keel` is cheap to type.

Use it when:

- a feature, refactor, migration, or multi-file change whose shape is not agreed
- the user says "spec it out", "define the criteria", "before we start", "let's
  plan"
- you catch yourself about to guess at requirements

Skip it when:

- rename, typo, mechanical edit, one obvious fix
- pure question or lookup
- the user explicitly asked for speed over verification

When unsure, ask: "This might be small enough to just do. Keel pass, or go?"

The user or the agent decides whether a spec is needed. Until that decision is
made, do not offer to write one.

## Small tasks

A small task ends at a gate in conversation. Confirm what to build, what not to
build, and how to verify it, then get approval before touching code. The
conversation is the only artifact: no `SPEC.md`, no vault note, no file to
commit. Keel is allowed to conclude the task is small and exit. An agent that
thinks a task is heavy and finds out it is not has learned something useful;
the cost of that discovery should be a few questions, not a spec.

## Flow

### 1. Interview first, write later

Explore and ask before writing anything. Reading code is safe; a spec is a
commitment, and you do not yet know whether the work earns it.

Extract intent before writing anything. Whatever the user asked for is a guess
at what they want; your job is to find the gap while it is still free to close.

Open with your current reading of what they want, in your own words, and name
what is still unclear. Then ask, grouping the questions in whatever way fits the
user and the uncertainty:

- **Phrase every question around your guess, so the user can correct it with
  one word.** Reacting is faster than generating. Never a label in front of it.
- Probe sophistication-signaling answers. "Scalable", "clean", "modern", "the
  standard approach" are conventions, not wants. Ask: _"If you didn't have to
  justify this to anyone, what would you actually want?"_
- Across the interview, cover at minimum: who benefits, why now, what success
  looks like, the binding constraint, and what is explicitly **not** being built.
  The first turn may ask only the most uncertain few.

Stop when you can predict the user's reaction to the next three questions you
would ask. That is a checkable test, not a vibe. If several rounds pass and your
understanding is not improving, say so and step back -- the ask itself is
broken.

### 2. Decide whether the work is large

The interview is also the measurement. If a few questions show the change is
one obvious edit, run the small-task gate and drop the spec. If the work is
large, name the evidence (files touched, behaviours changed, unknowns
remaining) so the spec is justified rather than assumed.

### 3. Record the background

Write the problem, who feels it and when, what was tried, and what fixed looks
like in `~/vault/research/<project>/<subject>.md`, a durable note. Read it only
when a non-obvious judgment needs it; do not make it part of every execution.
The spec keeps only what an executor needs to act.

### 4. Write the design and the criteria

Fill the template that matches the session language. Four parts matter most:

- **Current behavior** -- the paths a cold executor reads first, and what they
  do today. Move them into a worktree `SPEC.context.md` only when this section
  grows long, and link that file from the end of the section. Update these
  paths when they change.
- **Design** -- one line per decision that constrains implementation, with its
  reason. Link the research note when a non-obvious judgment depends on its
  background. Do not write Decisions or Log sections; git and conversation
  carry that history.
- **Acceptance criteria** -- observable outcomes as plain `-` conditions.
  Hang verification methods beneath each as tab-indented `- [ ]` lines: a
  command, or a manual step with the expected observation. "Login works" is
  not a criterion; "an expired token redirects to `/login` and preserves the
  return path" is. If you cannot say how to check a condition, split it until
  you can, or drop it. A condition that ends in the user's judgment states
  **what to decide**, never how to answer: no reply formats like "reply in one
  line". The verification step records the answer in whatever shape the user
  gives it.
- **Out of scope** -- non-negotiable. Half of misalignment is silent
  disagreement about what is not being built.
- **Stop conditions** -- task-specific limits only (attempts, time, files).
  The common ones -- the same failure twice, work outside the spec, a
  trade-off needing a human decision -- live in the sail skill. Omit the
  section when there are none. When work stops, add a `## Blocker` section on
  demand: what was tried, what happened, the likely cause, and the options.

Write the spec so it can be read **cold** -- by a session that has none of this
conversation. No "as discussed", no "the usual place". Paths, current behavior,
decisions and their reasons, commands. Keel's whole handoff story rests on this.

### 5. Hand the spec over

Point at the spec and say what it commits to. Do not repeat its sections back
in chat.

Do not ask for approval. Not "does this look right?", not "shall I go?", not
"confirm and I will start". The next move is theirs.

Then end the turn. Do not start implementing, do not "just scaffold", do not
open the first file. The gate is the feature; skipping the stop empties it out.

The spec stays `draft` until approval runs: an executor picking it up performs
the approval act above, and so does this session if the user approves here. Do
not commit the draft or the translation candidate; only the promoted
`SPEC.md`, together with `SPEC.context.md` when present, goes into the work
commit.

## Handoff

The spec is the only task-specific channel to an executor; the execution rules
live in the `sail` skill. When the work passes to another session or runner,
point it at the spec and `sail`, and make sure the stop conditions are explicit
enough that it stops rather than guesses.

A question from a cold executor is a spec defect. Answer it, write the answer
into the spec's design, out-of-scope, or acceptance-criteria sections, then let
it continue -- so the next cold run never has to ask.

## Red flags

- Starting to implement, or "just setting up", in the turn that opens the gate
- Asking for approval of the spec (a small task's approval to implement is
  different)
- Writing a spec into the vault, or migrating an old vault note
- Cutting a branch on your own initiative
- Offering to write a spec before its need has been decided
- Grinding through questions when the answer is already obvious
- Repeating the spec's sections back instead of pointing at it
- A spec that never says what is out of scope
- A condition with no way to check it
- A condition that dictates the user's reply format
- A quotation of the user, or a line transcribed from the conversation
- Writing the spec before the background is recorded
- Questions with no guess inside them, or the same label on every guess -- that
  is surveying, not interviewing
- A spec only readable by someone who was in the conversation
- Renegotiating a criterion after the work instead of reporting it unmet
- A draft left beside the promoted `SPEC.md` (`SPEC.ja.md` or `SPEC.en.md`)
- A translation that rewrites paths or code, or renames a heading and leaves
  references behind
- Common stop conditions copied into a spec
- Three or more rounds without your understanding improving

## Verification

- [ ] The work was judged large before the spec was written, or the gate ended
      at a small-task conversation
- [ ] The promoted spec is `SPEC.md` at the worktree root; no draft or
      candidate is committed and no working spec is in the vault
- [ ] Background is in a subject-scoped research note, not in the spec
- [ ] The design carries decisions and their reasons; conditions carry
      verification methods; out-of-scope is explicit
- [ ] The handoff did not repeat the spec and did not ask for approval of it
- [ ] No implementation started in the gate's turn
- [ ] Mid-work scope changes were written into the spec before acting
- [ ] The draft's filename and `session_lang:` match the language it is written
      in
- [ ] A spec approved this turn went translate -> check -> promote, with no
      draft or candidate left behind
