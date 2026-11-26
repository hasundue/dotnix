# Spec transitions

Read this when the user clears a block, drops the work, or resumes a stale spec.

Only on the user's word does a block clear: set `status: agreed` and move the
context from the blocker section into that commit's body before removing it.

If the user drops the work, set `status: stale`, move any blocker context into
that commit's body, and put why the work was dropped there.

Do not resume a stale spec without the user's word. On resumption, re-confirm
it, set `status: agreed`, and carry the context forward.
