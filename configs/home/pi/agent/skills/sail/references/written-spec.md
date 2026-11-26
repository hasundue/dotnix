# Written spec

Read this when the agreement lives in a written spec.

## Start

An execution-ready spec is `agreed`. If `status: blocked`, read the blocker
section first. If `status: stale`, stop and ask: the work was dropped. If
`status: draft`, stop and ask; it has not passed the gate.

## Checks

A method carries the observed value that decides its condition, not a
restatement of it: a count for a count, a state for a state. If the tick already
says everything, omit the line. An unmet method records the failing value or
reason instead. Never tick one to look busy, or reword the condition to make it
pass. Do not label method lines; the count of conditions stays separate from
the count of checks.

## Changes

In a written spec, update the design, out-of-scope, or acceptance criteria
before acting, and put why it moved and what was considered in that commit's
body.

When a stop needs a handoff, set `status: blocked`. The blocker section appears
only with that status; give it a heading in the spec's language that names the
block, and write the context needed to resume. A commit that only adds the
status and the section needs no body: the spec holds the context. Then ask.

A question the spec should answer is a spec defect. Answer it, write the answer
into the spec, and continue.

When the user clears a block, drops the work, or resumes a stale spec, read
`spec-transitions.md`.
