---
name: sail
description: >
  Execute an agreed spec from SPEC.md in the branch or worktree carrying the
  work: work the acceptance conditions with evidence, and stop on blockers
  instead of guessing. Use after a spec gate such as keel, when a spec has been
  agreed, or when the user hands over a spec to implement.
---

# Sail

Keel lays the spec; sail executes it. The agreement is already made. Do not
reopen the interview, rewrite the problem, or cut a branch unless the spec or
the user asks for it.

## Find the spec

- A path the user passed wins. An explicit path to an old vault task note is
  read as-is; do not migrate it.
- Otherwise read `SPEC.md` at the root of the current worktree, whatever
  language it is written in. Do not search the vault.
- If nothing matches, say so and ask. Never start without a spec.

When several specs fit equally, name them and ask which one. If the spec was
found rather than handed over, say which one you are taking -- path and title --
before starting; that is a report, not a request for approval.

Read the spec fully. If it is missing, empty, or has no acceptance criteria,
stop and ask. A `draft` spec is normal: the instruction here is the go, so
promote it by updating the status as `../keel/references/spec-authoring.md`
describes, then implement. If `status: blocked`, read the blocker section first.
If `status: stale`, stop and ask: the work was dropped.

A question from a cold executor is a spec defect. Answer it, write the answer
into the spec's design, out-of-scope, or acceptance criteria, then continue.

Then check the branch and working tree so you know what you are changing. Do not
push, rewrite history, or discard unrelated work unless the spec or the user
asks for it.

## Execute

Work through the acceptance conditions. Use each condition's `- [ ]` methods to
decide what to run or inspect.

- Tick a method when you carry it out, recording the command and its result, or
  what you observed and where.
- Leave a method unticked when its condition is unmet and add `unmet: <reason>`.
  Never tick one to look busy, or reword a condition to make it pass.
- If a condition is already satisfied, record the evidence instead of changing
  code.
- Follow the repository's rules for tests, formatting, and commits. Commit the
  promoted `SPEC.md` with the work; drafts are never committed.
- If the spec is silent on a local implementation detail, use judgment. Silence
  is not permission to change the agreed outcome.

Create or switch branches only when the user asks. If the work is on
`main`/`master` and the user has said nothing, ask instead of branching
silently. The spec belongs to where it was written; there is no branch field to
keep in sync.

## Scope changes and blockers

When reality contradicts the spec, update the design, out-of-scope, or
acceptance criteria before acting, then ask for re-confirmation. Put why the
spec moved and what was considered in that commit's body. Do not drift silently.

Stop when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the spec -- stop;
- a genuine trade-off needs a human decision -- stop.

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

## When the work is done

Read `references/verification.md`, walk the conditions once more, and report.
Leave the spec in place. When the user says to merge, read
`references/merge.md`.
