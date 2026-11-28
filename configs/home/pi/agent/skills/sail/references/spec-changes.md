# Spec changes

When a premise fails, the change goes back through the gate and the spec
follows the rules in `keel`'s `references/spec-authoring.md`.

When a handoff is needed, set `status: blocked`. The blocker section appears
only with that status and holds the context needed to resume. Clear the block
only on the user's word: set `status: agreed`, then remove the blocker section,
moving its context into the commit that carries the spec first when the spec is
committed.
