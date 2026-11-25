---
name: keel
description: >
  Pre-work gate for changes whose shape is not agreed: agree the problem, the
  design, and how the work will be checked before implementation starts, then
  hand control back. Use at the start of features, refactors, migrations, and
  other multi-file work while requirements are still open.
---

# Keel

## Gate

- Do not implement, scaffold, or open a file in the turn that opens the gate.
  Hand control back and let the user move first. Do not put the spec to a vote.
- Judge the size during the interview. A small task ends at a gate in
  conversation: confirm what to build, what not to build, and how to verify it,
  then get approval before touching code. No spec, note, or file to commit.
- A large task gets one `SPEC.md`. Name the evidence -- files touched,
  behaviours changed, unknowns remaining -- so the spec is justified.
- Scope changes move in the spec before anyone acts on them.
- Point at the spec and `sail` with explicit stop conditions, then end the turn.

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
cover what success looks like, the binding constraint, and what is explicitly
**not** being built. When an answer earns approval but names no choice, strip
the label and offer one concrete option.

Stop when there is no available decision left to put to the user and you can
predict the user's reaction to the next three questions you would ask. If
rounds pass without your understanding improving, say so and step back -- the
ask itself may be broken.

## Spec

One `SPEC.md` sits at the root of the branch or worktree that will carry the
work, in the language of the session that wrote it. Follow
`references/spec-authoring.md` for how to place, draft, and promote it.
