# Spec transitions

Read this when the user decides what to do with a blocked or stale spec.

Clear a block only on the user's word: set `status: agreed` and move the context
from the blocker section into that commit's body before removing it.

If the user drops the work, set `status: stale`, move any blocker context into
that commit's body, and put why the work was dropped there.

Resume a stale spec only on the user's word: re-confirm it, set the status to
`agreed`, and carry the context from the stale commit's body into the work.
