# Stops

Read this when a stop condition triggers, or when a spec arrives as `blocked`
or `stale`.

When reality contradicts the spec -- a constraint was wrong, a step is
impossible, a criterion is incomplete, or the work needs to grow -- update the
design, out-of-scope, or acceptance criteria before acting, then ask for
re-confirmation. Put why the spec moved and what was considered in that commit's
body. Do not drift silently.

When a stop needs a handoff, set `status: blocked`. The blocker section appears
only with that status; give it a heading in the spec's language that names the
block, and write the context needed to resume. A commit that only adds the
status and the section needs no body: the spec holds the context. Then ask.

Only on the user's word does a block clear: set `status: agreed` and move the
context from the blocker section into that commit's body before removing it. If
the user drops the work, set `status: stale`, move any blocker context into that
commit's body, and put why the work was dropped there. Do not resume a stale
spec without the user's word; on resumption, re-confirm it, set the status to
`agreed`, and carry the context forward.
