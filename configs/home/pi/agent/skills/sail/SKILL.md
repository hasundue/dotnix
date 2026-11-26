---
name: sail
description: >
  Execute the agreement made at a keel gate: work its conditions with evidence,
  and stop on blockers instead of guessing. Use when the user hands over work
  to implement.
---

# Sail

Keel makes the agreement; sail carries it out. Do not reopen the interview,
rewrite the problem, or cut a branch unless the agreement or the user asks.

## Find the agreement

Find it in the session context: a path the user passed, a written spec the
project or user points to, or the live conversation. If none is there, or it
has no way to verify, stop and ask.

If it came from a written spec, read `references/written-spec.md`. If several
fit, name them and ask. If you found it yourself, say which one you are taking
before starting; that is a report, not a request for approval.

## Execute

Before changing code, check the branch and working tree. Do not push, rewrite
history, or discard unrelated work unless the agreement or the user asks.

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
When the user says to merge, follow the repository's merge procedure; if there
is none, stop and ask.
