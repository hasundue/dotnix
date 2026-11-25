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

Gate before build: agree the problem, the design, and how the work will be
checked where it will be committed. Then hand control back.

## Gate

- Do not implement, scaffold, or open a file in the turn that opens the gate.
  Hand control back and let the user move first. Do not put the spec to a vote.
- Judge the size during the interview. A small task ends at a gate in
  conversation: confirm what to build, what not to build, and how to verify it,
  then get approval before touching code. No spec, note, or file to commit.
- A large task gets one `SPEC.md`. Name the evidence -- files touched,
  behaviours changed, unknowns remaining -- so the spec is justified.
- Scope changes move in the spec before anyone acts on them.

## Interview

Treat what is still undecided as a graph of dependencies. A decision can be put
to the user only once the decisions it depends on are settled. From those
available now, pick the one whose answer decides the most downstream work and
ask a single question about it. Frame it around your guess so the user can
correct it with one word.

Wait for the answer, then update which decisions are available. A decision that
depends on an open one stays back; do not ask it with a guessed premise. Do not
send several questions in one message.

Find facts yourself; ask the user only for decisions. Across the interview,
cover who benefits, why now, what success looks like, the binding constraint,
and what is explicitly **not** being built. Probe words like "scalable",
"clean", "modern", and "the standard approach" by asking what the user would
want without having to justify it to anyone.

Stop when there is no available decision left to put to the user and you can
predict the user's reaction to the next three questions you would ask. If
rounds pass without your understanding improving, say so and step back -- the
ask itself may be broken.

## Spec

One `SPEC.md` sits at the root of a linked worktree, in the language of the
session that wrote it. Drafts stay uncommitted and are deleted if the work is
dropped; only a promoted spec is committed with the work.

Keel does not create branches or worktrees, write vault notes, or migrate old
ones. Follow `references/spec-lifecycle.md` for the worktree check, templates,
format, status, checks, promotion, and blocker handling.

## Handoff

The spec is the only task-specific channel to an executor. Hand it over with
`sail` and stop; do not ask for approval of the spec and do not start the work.
Follow `references/handoff.md` for what to say, how to handle a cold executor's
question, and who promotes the spec.
