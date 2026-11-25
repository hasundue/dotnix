---
name: sail
description: >
  Execute the agreement made at a keel gate: work its conditions with evidence,
  and stop on blockers instead of guessing. Use when a task has been agreed or
  when the user hands over work to implement.
---

# Sail

Keel makes the agreement; sail carries it out. Do not reopen the interview,
rewrite the problem, or cut a branch unless the agreement or the user asks.

## Find the agreement

The agreement is what the gate settled: what to build, what not to build, and
how to verify it. Find it in this order: a path the user passed, `SPEC.md` at
the root of the current worktree, or a completed gate in the live conversation.
An explicit path to an old vault task note is read as-is; do not migrate it.
Do not search the vault.

A spec carries its own rules in `references/spec-carrier.md`; a cold session
with no spec has no agreement and stops. If the agreement is missing, empty, or
has no way to verify, stop and ask.

When several choices fit equally, name them and ask which one. If the agreement
was found rather than handed over, say which one you are taking -- path or gate,
and title -- before starting; that is a report, not a request for approval.

Then check the branch and working tree so you know what you are changing. Do not
push, rewrite history, or discard unrelated work unless the agreement or the
user asks for it.

## Execute

Work through the agreed conditions. Use each condition's verification method to
decide what to run or inspect.

- Record what proves a condition: the command and its result, or what you
  observed and where.
- If a condition is unmet, leave it unmet with `unmet: <reason>`; never mark it
  done to look busy, or reword a condition to make it pass.
- If a condition is already satisfied, record the evidence instead of changing
  code.
- Follow the repository's rules for tests, formatting, and commits.
- If the agreement is silent on a local implementation detail, use judgment.
  Silence is not permission to change the agreed outcome.

Create or switch branches only when the user asks. If the work is on
`main`/`master` and the user has said nothing, ask instead of branching
silently.

## Stop

When reality contradicts the agreement, put the change in front of the user
before acting.

Stop when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the agreement -- stop;
- a genuine trade-off needs a human decision -- stop.

When a stop happens, report it and wait for the user's decision.

## When the work is done

Read `references/verification.md`, walk the conditions once more, and report.
When the user says to merge, read `references/merge.md`.
