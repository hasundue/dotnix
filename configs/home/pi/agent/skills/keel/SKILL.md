---
name: keel
description: >
  Pre-work spec gate for large changes: agree the problem, the spec, and the
  acceptance criteria in one task note, then hand control back before
  implementing. Use at the start of a feature, refactor, migration, or any
  multi-file change whose shape is not yet agreed; when the user says "spec it
  out", "define the criteria", "before we start", "let's plan"; or when you are
  about to guess at requirements.
---

# Keel

Lay the keel before the hull: agree on the problem, the spec, and the acceptance
criteria, and write them where a merge cannot lose them. Then hand control back.

Keel is not a mode and not a pipeline. It has four invariants you may not skip
and a toolbox you use at your discretion. As models get better, the toolbox
should be used better; the invariants should shrink, not grow.

## Invariants

1. **Nothing is implemented in the turn that writes the note, and no approval is
   asked for: hand control back and let the user move first.**
2. **The work is either declared small or has one note with a problem, a spec,
   and acceptance criteria.**
3. **The note names what is out of scope.**
4. **If scope moves mid-work, it moves in the note before anyone acts on it.**

Everything else -- how many questions, whether to research first, how the note
is organized -- is judgment.

## The note

One file per task, kept outside the repository:

```
~/notes/projects/<project>/<YYYY-MM-DD>-<slug>.md
```

Resolve the project from git, so worktrees land on the main checkout:

```sh
basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
# ~/dotnix.pi-workflow -> dotnix
```

Not in a git repository? Ask for the project; do not guess. Create the directory
if it is missing.

Pick `<slug>` yourself, in kebab-case, from the task. Do not ask the user to
name the file: they will rename it if they dislike it, and discovery does not
depend on the filename. The date is the creation date, not the last edit.

The repository gets no copy. No working note belongs in the tree, and none is
ever committed.

## Finding an existing note

Before starting a second note for the same task:

1. A path the user passed wins.
2. Otherwise search the project's notes by the task's own words -- title,
   problem, branch -- with `rg -il` over `~/notes/projects/<project>/`, keeping
   notes whose `status` is not `done`. Branch is the weakest of the three: keel
   records the branch it ran on, which is often `main`.
3. Otherwise list that project's notes with `status != done`, newest first
   (`ls -t`), and ask which one.
4. Otherwise ask. Never guess.

A person who names a task in passing has not asked for a second note on it. Find
the first one before you write.

## Branches

Branches are execution's business, not the gate's. Do not cut one on your own
initiative. If the user says "cut a branch and go", do that and record it in
`branch:`; otherwise record whatever branch you are on.

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

Keel is allowed to conclude the task is small and exit. An agent that thinks a
task is heavy and finds out it is not has learned something useful; the cost of
that discovery should be a few questions, not a note.

## Flow

### 1. Interview first, write later

Explore and ask before writing anything. Reading code is safe; a note is a
commitment, and you do not yet know whether the work earns it.

Extract intent before writing anything. Whatever the user asked for is a guess
at what they want; your job is to find the gap while it is still free to close.

Open with your current reading of what they want, in your own words, and name
what is still unclear. Then ask, grouping the questions in whatever way fits the
user and the uncertainty:

- **Attach your guess to every question.** Reacting is faster than generating,
  and it exposes your assumptions where the user can correct them.
- Probe sophistication-signaling answers. "Scalable", "clean", "modern", "the
  standard approach" are conventions, not wants. Ask: _"If you didn't have to
  justify this to anyone, what would you actually want?"_
- Cover, at minimum: who benefits, why now, what success looks like, the binding
  constraint, and what is explicitly **not** being built.

Stop when you can predict the user's reaction to the next three questions you
would ask. That is a checkable test, not a vibe. If several rounds pass and your
understanding is not improving, say so and step back -- the ask itself is
broken.

### 2. Decide whether the work is large

The interview is also the measurement. If a few questions show the change is one
obvious edit, say so and drop keel: no note, just do the work. That is a
success, not a bail-out -- the ceremony was avoided, which is the point.

If the work is large, name the evidence (files touched, behaviours changed,
unknowns remaining) so the note is justified rather than assumed.

### 3. Write the problem

Write the problem before the solution, and keep the solution out of it. Use the
user's words verbatim where you can, in quotes. If you only have a paraphrase,
put it under `## Design`; do not dress it up as a quote. Include what was tried
and why it was not enough. If you cannot state the problem without naming an
implementation, you have not found it yet.

Show the note. Let them correct it.

### 4. Write the design and the criteria

Fill the template in `references/templates.md`. Three parts matter most:

- **Acceptance criteria** -- observable outcomes, not activities. "Login works"
  is not a criterion; "an expired token redirects to `/login` and preserves the
  return path" is. Each one gets a `verify:` -- a command, or a manual step. If
  you cannot say how to check it, split it until you can, or drop it. A
  criterion nobody can check is decoration. A criterion that ends in the user's
  judgment (a listen, a look, a preference) states **what to decide**, never how
  to answer: no reply formats like "reply in one line" or "answer with X". The
  verify step records the answer in whatever shape the user gives it.
- **Out of scope** -- non-negotiable. Half of misalignment is silent
  disagreement about what is not being built.
- **Stop conditions** -- when to stop instead of grinding. Defaults:
  - the same failure twice -> write the cause, stop
  - the work needs to touch something outside the spec -> stop
  - a genuine trade-off needs a human decision -> stop

  Add per-task limits (attempts, time, files) when the task invites a rabbit
  hole. Stopping is not failing, but it must leave a trace: write the situation
  under `## Blocker`, then ask. Never stop silently.

Write the note so it can be read **cold** -- by a session that has none of this
conversation. No "as discussed", no "the usual place". Paths, current behavior,
decisions and their reasons, commands. Keel's whole handoff story rests on this.

### 5. Hand the note over

The note already carries the outcome, who it is for, why now, what success looks
like, the binding constraint, and what is out of scope. Point at it and say what
it commits to. Do not repeat those sections back in chat.

Do not ask for approval. Not "does this look right?", not "shall I go?", not
"confirm and I will start". If the user wants a confirmation step they will ask
for one; the next move is theirs.

Then end the turn. Do not start implementing, do not "just scaffold", do not
open the first file. The gate is the feature; skipping the stop empties it out.

The note stays `draft` until an executor picks it up and marks it `agreed`:
there is nothing for the gate to record, and nothing to commit, because the note
is already outside the repository.

## Handoff

The note is the only task-specific channel to an executor; the execution rules
live in the `sail` skill. When the work passes to another session or runner,
point it at the note and `sail`, and make sure the stop conditions are explicit
enough that it stops rather than guesses.

A question from a cold executor is a spec defect. Answer it, write the answer
into the note, then let it continue -- so the next cold run never has to ask.

## Red flags

- Starting to implement, or "just setting up", in the same turn as the note
- Asking for approval, or re-asking after a vague answer
- Writing a working note into the repository
- Cutting a branch on your own initiative
- Asking the user to name the note
- Grinding through questions when the answer is already obvious
- Repeating the note's sections back instead of pointing at it
- A note that never says what is out of scope
- A criterion with no `verify:`
- A criterion that dictates the user's reply format
- A paraphrase presented as a quote under "in the user's words"
- Writing the spec before the problem
- Questions with no guess attached -- that is surveying, not interviewing
- A note only readable by someone who was in the conversation
- Renegotiating a criterion after the work instead of reporting it unmet
- Three or more rounds without your understanding improving

## Verification

- [ ] The work was judged large before the note was written, or keel exited
      early
- [ ] The note is under `~/notes/projects/<project>/`; the repo has no working
      note
- [ ] The problem section contains no solution
- [ ] Criteria, each with `verify:`, plus out-of-scope and stop conditions
- [ ] The note says what is out of scope; the handoff did not repeat the note
- [ ] No approval was requested, and the note was left `draft` for the executor
- [ ] The turn ended at the note; no implementation started
- [ ] Mid-work scope changes were written to the note before acting
