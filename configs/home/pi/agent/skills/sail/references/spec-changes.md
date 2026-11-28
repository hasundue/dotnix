# Spec changes

When a premise fails, the change goes back through the gate and the spec
follows the rules in `keel`'s `references/spec-authoring.md`.

When a handoff is needed, set `status: blocked`. The blocker section appears
only with that status and holds the context needed to resume. Clear the block
only on the user's word: set `status: agreed` and move the context from the
blocker section into the spec's history before removing the section. Version
control in `keel`'s `references/spec-authoring.md` defines the spec's history.
