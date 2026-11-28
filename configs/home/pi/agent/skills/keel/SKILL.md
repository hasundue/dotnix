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

- Do not implement, scaffold, or create or edit a file in the turn that opens
  the gate. Hand control back and let the user move first.
- Judge the size during the interview. A small task ends at a gate in
  conversation: confirm what to build, what not to build, and how to verify it,
  then get approval before touching code. No spec, note, or file to commit.
- A large task gets a written spec. Name the evidence -- files touched,
  behaviours changed, unknowns remaining -- so the spec is justified.
- Scope changes move in the agreement before anyone acts on them.
- Point at the agreement with explicit stop conditions, then end the turn.

## Interview

Treat what is still undecided as a graph of dependencies. A decision can be put
to the user only once the decisions it depends on are settled. From those
available now, pick the one whose answer decides the most downstream work and
ask a single question about it. Attach the answer you would choose; a concrete
answer is easier to reject than an open question.

Wait for the answer, then update which decisions are available. A decision that
depends on an open one stays back; do not ask it with a guessed premise. Do not
send several questions in one message.

Find facts yourself; ask the user only for decisions. Across the interview,
cover what success looks like, the binding constraint, and what is explicitly
**not** being built. When an answer approves without naming a choice, turn it
into one concrete option.

Stop when every decision still available would leave the agreement as it
stands. If rounds pass without your understanding improving, say so and step
back -- the ask itself may be broken.

## Spec

A large task carries its agreement in a written spec, in the language of the
session that wrote it. Its name, location, and git handling follow the project's
convention unless the user says otherwise; read that convention rather than
asking, and ask only when it is silent. Follow `references/spec-authoring.md`
for how to draft and promote it.
