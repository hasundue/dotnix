---
name: keel
description: >
  Pre-work spec gate for large changes: agree the problem, the design, and the
  acceptance criteria in a SPEC.md in the linked worktree, then hand control
  back before implementing. Use at the start of a feature, refactor, migration,
  or any multi-file change whose shape is not yet agreed; when the user says
  "spec it out", "define the criteria", "before we start", "let's plan"; or
  when you are about to guess at requirements.
---

# Keel

Lay the keel before the hull: agree on the problem, the design, and how it will
be checked where the work will be committed, then hand control back.

Keel is not a mode and not a pipeline. It has four invariants you may not skip
and a toolbox you use at your discretion. As models get better, the toolbox
should be used better; the invariants should shrink, not grow.

## Invariants

1. **Nothing is implemented in the turn that opens a gate: hand control back
   and let the user move first. Do not put the spec to a vote.**
2. **The work is either declared small and gated in conversation, or has one
   `SPEC.md` with a problem, a design, and acceptance criteria.**
3. **The spec names what is out of scope.**
4. **If scope moves mid-work, it moves in the spec before anyone acts on it.**

Everything else -- how many questions, whether to research first, how the spec
is organized -- is judgment.

## The spec

One `SPEC.md` sits at the root of a linked worktree. A worktree maps one-to-one
to a branch, so the spec needs no branch field. Sail commits the promoted spec
with the work and leaves it out of the commits that land on `main`.

Before writing anything, check where you are:

- Work in a linked worktree. In the primary checkout, stop and ask the user to
  switch to one. Keel does not create worktrees or branches; a worktree is a
  branch.
- If any `SPEC*` file already exists there, tracked or not, it is a spec. Read
  it and ask before drafting another. Never overwrite or rename one on your own.

```sh
git rev-parse --path-format=absolute --git-dir --git-common-dir
git ls-files 'SPEC*'; ls SPEC* 2>/dev/null
```

The two `rev-parse` lines differ only in a linked worktree.

A Japanese session drafts `SPEC.ja.md`; an English session drafts `SPEC.md`.
Drafts and candidates stay uncommitted. `references/spec-lifecycle.md` covers
their translation, check, and promotion.

Keel writes no notes into the vault. An old vault note is read only when its
path is passed explicitly, and is never migrated.

## Language and the approval act

Use the template matching the session language: `references/templates.ja.md` or
`references/templates.en.md`. Do not read the other one just to write a draft.

Keel writes the draft and stops. Approval belongs to whoever the user hands the
work to: sail, or this session if the user approves here. When the user
approves here, run `references/spec-lifecycle.md`: translate, check, and
promote. From approval on, the spec is English for life, and it restates what
the user wants rather than quoting them.

## Branches

Branches are execution's business, not the gate's. Do not cut one, or create a
worktree for one, on your own initiative. The spec sits on whatever branch the
work is on.

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
conversation is the only artifact: no `SPEC.md`, no note, no file to commit.
Keel is allowed to conclude the task is small and exit. An agent that thinks a
task is heavy and finds out it is not has learned something useful; the cost of
that discovery should be a few questions, not a spec.

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

### 3. Write the problem

The problem is the spec's first section: the reason for the change, in two to
four lines, with no solution in it. It is what an executor uses to judge a
trade-off, so state it plainly enough for that. History -- who hit it, what was
tried -- stays out unless it changes a decision. When the branch is reorganized for the merge, the problem becomes the body of the
commit that lands its outcome (`git-workflow`), so the reason outlives the spec.

### 4. Write the design and the criteria

Fill the template that matches the session language. Four parts matter most:

- **Design** -- one line per decision that constrains implementation, with its
  reason. Name the paths a decision depends on in its own line. Do not write
  Decisions or Log sections; git and conversation carry that history.
- **Acceptance criteria** -- observable outcomes as plain `-` conditions. Hang
  verification methods beneath each as two-space-indented `- [ ]` lines: a command, or
  a manual step with the expected observation. "Login works" is not a criterion;
  "an expired token redirects to `/login` and preserves the return path" is. If
  you cannot say how to check a condition, split it until you can, or drop it. A
  condition that ends in the user's judgment states **what to decide**, never
  how to answer: no reply formats like "reply in one line". The verification
  step records the answer in whatever shape the user gives it.
- **Out of scope** -- non-negotiable. Half of misalignment is silent disagreement
  about what is not being built.
- **Stop conditions** -- task-specific limits only (attempts, time, files). The
  common ones -- the same failure twice, work outside the spec, a trade-off
  needing a human decision -- live in the sail skill. Omit the section when
  there are none. When work stops, add a `## Blocker` section on demand: what was
  tried, what happened, the likely cause, and the options.

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

The spec stays `draft` until approval runs. An executor who picks it up performs
the approval act, and so does this session if the user approves here. Drafts
stay uncommitted (see `references/spec-lifecycle.md`).

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
- Writing a spec or note into the vault, or migrating an old vault note
- Cutting a branch, or creating a worktree, on your own initiative
- Writing a draft in the primary checkout, or over an existing `SPEC*` file
- Offering to write a spec before its need has been decided
- Grinding through questions when the answer is already obvious
- Repeating the spec's sections back instead of pointing at it
- A spec that never says what is out of scope
- A condition with no way to check it, or one that dictates the user's reply
  format
- A quotation of the user, or a line transcribed from the conversation
- Renegotiating a criterion after the work instead of reporting it unmet
- A spec only readable by someone who was in the conversation
- Three or more rounds without your understanding improving

## Verification

- [ ] The work was judged large before the spec was written, or the gate ended
      at a small-task conversation
- [ ] The draft is in a linked worktree, under the name the session language
      calls for, and no other `SPEC*` file existed there
- [ ] The problem is two to four lines; the design carries decisions with their
      reasons; conditions carry verification methods; out-of-scope is explicit
- [ ] The handoff did not repeat the spec and did not ask for approval of it
- [ ] No implementation started in the gate's turn
- [ ] A spec approved this turn went through `spec-lifecycle.md` with no draft
      or candidate left behind
