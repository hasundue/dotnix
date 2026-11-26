# Written spec

Read this when the agreement lives in a written spec.

## Promotion

A `draft` spec is normal: the instruction to execute is the go, so promote it
by updating the status to `agreed` as `../keel/references/spec-authoring.md`
describes. Do not ask whether it is agreed. Commit the promoted spec with the
work; drafts are never committed.

## Status and blockers

If `status: blocked`, read the blocker section first. If `status: stale`, stop
and ask: the work was dropped.

When reality contradicts the spec, update the design, out-of-scope, or
acceptance criteria before acting, then ask for re-confirmation. Put why the
spec moved and what was considered in that commit's body. Do not drift silently.

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

## Cold executor

A question from a cold executor is a spec defect. Answer it, write the answer
into the spec's design, out-of-scope, or acceptance criteria, then continue.

The spec keeps its language for life; reports speak the language of the
conversation. If the session gives no signal, ask which language to report in.
There is no Log section: record decisions in conversation and commit messages.

## Handoff

Leave the spec in place after reporting.
