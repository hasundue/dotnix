# Written spec

Read this when the agreement lives in a written spec.

## Start

An execution-ready spec is `agreed`. If `status: blocked`, read the blocker
section first. If `status: stale`, stop and ask: the work was dropped. If
`status: draft`, stop and ask; it has not passed the gate.

## Results

Record each report under its verification method in the spec: the observed
value when met, the failing value or reason when unmet.

## Changes

When a premise fails, update the design, out-of-scope, or acceptance criteria
before acting, and put why it moved and what was considered in that commit's
body.

When a handoff is needed, set `status: blocked`. The blocker section appears
only with that status and holds the context needed to resume. The blocker commit
needs no body; the spec holds the context.

Read `spec-transitions.md` when the user decides what to do with a blocked or
stale spec.
