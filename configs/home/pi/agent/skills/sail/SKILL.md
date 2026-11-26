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

Work through the agreed conditions. Use each condition's verification method to
decide what to run or inspect.

- Record evidence for each condition: the command and its result, or what you
  observed and where. An already satisfied condition still needs evidence.
- An unmet condition stays unmet. Never tick it to look busy, or reword it to
  make it pass.
- If the agreement is silent on a local detail, use judgment. Silence is not
  permission to change the agreed outcome.

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
