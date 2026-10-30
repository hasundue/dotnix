# Templates

Skeletons for the two files keel writes. The headings are load-bearing; the
prose under them is not. Keep them short -- a spec nobody rereads is not a spec.

## ISSUE.md -- problem only

```markdown
# ISSUE -- <short title>

## What's wrong

<The problem, as plainly as possible. No solution, no implementation.>

## Who feels it, and when

<Who hits this, at what moment, and what it costs them.>

## What was tried

<Prior attempts and why they were not enough. Omit if none.>

## What "fixed" looks like -- in the user's words

> "<verbatim quote>"

## Open questions

- <Anything still unresolved.>
```

## SPEC.md -- the agreement

```markdown
# SPEC -- <short title>

## Goal

<One paragraph. What is true after this work that is not true now.>

## Background

<What a cold reader needs: paths, current behaviour, prior decisions and why.>

## Acceptance criteria

- <observable outcome>
      verify: `<command>` / <manual step with expected observation>
- <observable outcome>
      verify: `<command>`

## Out of scope

- [ ] <What we are explicitly not building, and why, if non-obvious.>

## Stop conditions

- The same failure twice -> write the cause under `## Blocker`, stop
- Needs to touch something outside this spec -> stop
- A trade-off that needs a human decision -> stop
- <Per-task limit: attempts, time, files.>

## Decisions

- <date> -- <decision> -- <reason>

## Confirmed

- <date> -- user: "<their words>"

## Notes

<Free-form: research, dead ends, open questions, sketches.>
```

## Filled example (compact)

```markdown
# SPEC -- Expire sessions on idle, not on a fixed clock

## Goal

Sessions end after 30 minutes of inactivity instead of 24 hours after login.
Active users are no longer logged out mid-task.

## Background

`src/auth/session.ts` sets `expiresAt = issuedAt + 24h` at login and never
touches it again. `tests/auth/session.test.ts` asserts the 24h value today, so
it will need updating.

## Acceptance criteria

- [ ] A request 31 minutes after the last one is rejected with 401 verify:
      `pnpm test tests/auth/session.test.ts -t idle`
- [ ] A request 29 minutes after the last one succeeds, and resets the clock
      verify: same test file, `-t active`
- [ ] The 24h absolute cap still applies verify: `-t absolute`

## Out of scope

- Remember-me, sliding refresh tokens, per-role timeouts
- Migrating existing sessions (they expire on the old rule)

## Stop conditions

- Same failure twice -> stop and report
- Touching anything under `src/billing/` -> stop

## Decisions

- 2025-11-30 -- idle timeout only, no absolute cap change -- smaller diff, and
  the cap is a compliance requirement

## Confirmed

- 2025-11-30 -- user: "go that way"
```
