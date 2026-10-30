---
name: keel
description: >
  Pre-work spec gate for large changes. Before implementing, lays down a problem
  statement (ISSUE.md) and an agreed spec with acceptance criteria (SPEC.md) on a
  working branch, then stops until the user gives an explicit yes. Use at the
  start of a feature, refactor, migration, or any multi-file change whose shape
  is not yet agreed; when the user says "spec it out", "define the criteria",
  "before we start", or "let's plan"; or when you catch yourself about to
  guess at requirements. When unsure whether a task is large enough, ask
  instead of auto-invoking.
---

# Keel

Lay the keel before the hull: agree on the problem, the spec, and the acceptance
criteria, and cut a branch only when the work earns one. Then stop until the
user says yes.

Keel is not a mode and not a pipeline. It has four invariants you may not skip
and a toolbox you use at your discretion. As models get better, the toolbox
should be used better; the invariants should shrink, not grow.

## Invariants

1. **Nothing is implemented before the user's explicit yes.**
2. **Before that yes, the work is either declared small or has `ISSUE.md` and
   `SPEC.md` committed on a working branch.**
3. **The restate names what is out of scope.**
4. **If scope moves mid-work, it moves in the file and gets re-confirmed.**

Everything else -- how many questions, whether to research first, how to phrase
the restate -- is judgment.

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
that discovery should be a few questions, not a branch.

## Flow

### 1. Interview first, branch later

Explore and ask before changing anything. Reading code is safe on any branch;
cutting one is a commitment, and you do not yet know whether the work earns it.

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
obvious edit, say so and drop keel: no branch, no files, just do the work. That
is a success, not a bail-out -- the ceremony was avoided, which is the point.

If the work is large, name the evidence in one line (files touched, behaviours
changed, unknowns remaining) so the branch is justified rather than assumed.

### 3. Branch

Only now. If on `main` or `master`, create a branch:

```bash
git switch -c <branch-name>
```

If already on a feature branch, stay on it -- do not nest branches. Say which
branch you are on. Do not push.

### 4. Write `ISSUE.md` -- problem only

Write the problem before the solution, and keep the solution out of it. Use the
user's words verbatim where you can, in quotes. Include what was tried and why
it was not enough. If you cannot state the problem without naming a
implementation, you have not found it yet.

Show the file. Let them correct it.

### 5. Write `SPEC.md` -- the agreement

Fill the skeleton in `references/templates.md`. Three parts matter most:

- **Acceptance criteria** -- observable outcomes, not activities. "Login works"
  is not a criterion; "an expired token redirects to `/login` and preserves the
  return path" is. Each one gets a `verify:` -- a command, or a manual step. If
  you cannot say how to check it, split it until you can, or drop it. A
  criterion nobody can check is decoration.
- **Out of scope** -- non-negotiable. Half of misalignment is silent
  disagreement about what is not being built.
- **Stop conditions** -- when to stop instead of grinding. Defaults:
  - the same failure twice -> write the cause, stop
  - the work needs to touch something outside the spec -> stop
  - a genuine trade-off needs a human decision -> stop

  Add per-task limits (attempts, time, files) when the task invites a rabbit
  hole. Stopping is not failing, but it must leave a trace: write the situation
  under `## Blocker`, then ask. Never stop silently.

Write the file so it can be read **cold** -- by a session that has none of this
conversation. No "as discussed", no "the usual place". Paths, current behavior,
decisions and their reasons, commands. Keel's whole handoff story rests on this.

### 6. Restate and ask for an explicit yes

Restate the agreed outcome, who it is for, why now, what success looks like, the
binding constraint, and what is out of scope. Use their language and keep it
tight; do not force it into a fixed template.

Ask for an explicit yes. These are **not** yes: "whatever you think", "sounds
good", "sure, let's go", silence followed by "okay, start". They are delegation
or polite exits. Re-ask with two concrete options instead. If they correct you,
fold it in and restate.

### 7. On yes: record it, then stop the turn

Add to `SPEC.md`:

```markdown
## Confirmed

2025-12-01 -- user: "go that way"
```

Commit the two files on the branch, as their own commit:

```bash
git add ISSUE.md SPEC.md
git commit -m "keel: <slug>"
```

The commit is what makes the branch guard meaningful -- an untracked file is
invisible to it, and follows you across branch switches.

Then **end the turn**. Do not start implementing, do not "just scaffold", do not
open the first file. The gate is the feature; skipping the stop empties it out.
Hand control back and let the user choose how to proceed.

## Handoff

The spec is the only task-specific channel to an executor; the execution rules
live in the `sail` skill. When the work passes to another session or runner,
point it at `ISSUE.md`, `SPEC.md`, and `sail`, and make sure the spec's stop
conditions are explicit enough that it stops rather than guesses.

A question from a cold executor is a spec defect. Answer it, write the answer
into `SPEC.md`, then let it continue -- so the next cold run never has to ask.

## Optional: keep the notes off main

`scripts/install-hook.sh` installs a `pre-push` guard that rejects pushes to
`main`/`master` whose tree still contains `ISSUE.md` or `SPEC.md`. It is a
broom, not a judge: it checks presence, not truth, and `git push --no-verify`
overrides it. Offer it once; never install it unasked.

## Red flags

- Starting to implement, or "just setting up", in the same turn as the yes
- Cutting a branch before the interview shows the work is large
- Grinding through questions when the answer is already obvious
- A restate that omits what is out of scope
- Accepting "whatever you think" as a terminal answer
- A criterion with no `verify:`
- Writing the spec before the problem
- Questions with no guess attached -- that is surveying, not interviewing
- A spec only readable by someone who was in the conversation
- Renegotiating a criterion after the work instead of reporting it unmet
- Three or more rounds without your understanding improving

## Verification

- [ ] The work was judged large before a branch was cut, or keel exited early
- [ ] If large: branch is not `main`/`master`
- [ ] `ISSUE.md` states the problem and contains no solution
- [ ] `SPEC.md` has criteria, each with `verify:`, plus out-of-scope and stop
      conditions
- [ ] A restate was written back, including out of scope
- [ ] The user said yes explicitly; "sounds good" was re-asked
- [ ] `## Confirmed` records the date and the user's words
- [ ] Both files are committed on the branch
- [ ] The turn ended at the gate; no implementation started
- [ ] Mid-work scope changes were written to the file before acting
