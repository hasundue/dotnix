---
name: sail
description: >
  Execute an agreed spec. Use after a spec gate such as keel, or whenever a task
  note at ~/notes/projects/<project>/<YYYY-MM-DD>-<slug>.md already defines the
  problem, acceptance criteria, and stop conditions. Finds the note from the
  current branch, works each criterion with its verify step, ticks criteria with
  evidence, updates the note before changing scope, stops on blockers instead of
  guessing, and reports evidence per criterion. Use when the user says "execute
  the spec", "start the work", "implement the plan", or hands off an agreed
  note.
---

# Sail

Keel lays the spec; sail executes it. The agreement is already made. Do not
reopen the interview, rewrite the problem, or cut a branch unless the spec or
the user asks for it.

## Invariants

1. **Find and read the task note before touching code.**
2. **Every acceptance criterion ends with evidence or an explicit unmet
   report.**
3. **Closing and merging wait for the user's word; neither is asked for.**
4. **Scope moves in the note first, then gets re-confirmed.**
5. **A blocker is written down and raised, never silently absorbed.**
6. **Report in the language of the task note.**

Everything else -- implementation order, commits, test commands -- follows the
repo and the note.

## Find the note

1. A path the user passed wins.
2. Otherwise look in `~/notes/projects/<project>/` for a note whose `branch:`
   matches the current branch and whose `status` is not `done`.
3. Otherwise list that project's notes with `status != done`, newest first
   (`ls -t`), and ask which one.
4. Otherwise ask. Never guess.

The project name comes from git, so worktrees resolve correctly:

```sh
basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
# ~/dotnix.pi-workflow -> dotnix
```

Read the note fully. If it is missing, empty, or has no acceptance criteria,
stop and ask. If `confirmed:` is empty the note is still a draft; do not ask
whether it is agreed. The instruction that brought you here is the go: record it
under `## Confirmed` and set `confirmed:` before implementing. If
`status: blocked`, read `## Blocker` first. If `status: done`, there is nothing
to execute.

Then check the current branch and working tree so you know what you are
changing. Do not push, rewrite history, or discard unrelated work unless the
note or the user asks for it.

## Branches

Create or switch branches only when the user asks. If the work is on
`main`/`master` and the user has said nothing, ask instead of branching
silently. Keep `branch:` in the note in step with the branch actually used.

## Execute

Work through the acceptance criteria, not through a feeling of doneness. Use
each criterion's `verify:` to decide what to run or inspect.

- Tick each criterion as you verify it, with one line of evidence indented
  beneath: the command and its result, or what you observed and where.
- Leave missed criteria unticked and add `unmet: <reason>`. Never tick one to
  look busy, and never reword one to make it pass.
- If a criterion is already satisfied, record the evidence instead of changing
  code.
- Follow the repository's own rules for tests, formatting, and commits.
- If the note is silent on a local implementation detail, use judgment and note
  it under `## Log`; silence is not permission to change the agreed outcome.

## Scope changes and blockers

When reality contradicts the note -- a constraint was wrong, a step is
impossible, a criterion is incomplete, or the work needs to grow -- update the
note before acting, then ask for re-confirmation. Do not drift silently.

Stop instead of grinding when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the spec -- stop;
- a genuine trade-off needs a human decision -- stop.

Write the situation under `## Blocker`: what was tried, what happened, the
likely cause, and the options you see. Set `status: blocked`. Then ask. A stop
without a written trace is a failed handoff.

## Verify and close

Walk the acceptance criteria one by one and report evidence per item: the
command and its result, or what you observed and where. Unmet criteria are
reported as unmet, not renegotiated after the fact.

Do not call the work done because the diff looks plausible. The criteria decide.
Report what passed and what is unmet, then leave the note open: `status: done`
is set when the user says the task is closed. Do not ask whether to close, and
do not close it on your own.

End with a compact report in the note's language: what changed, which criteria
passed with what evidence, what is unmet, and what still needs a decision. The
next action is the user's.

When the next action is the user's judgment -- a listen, a look, a preference --
ask for the judgment itself, not for a format. Never dictate the shape of the
user's reply ("in one line", "as a table"); the note's criteria bind what is
decided, not how the user speaks. Record their answer under `## Log` as they
gave it, quoting verbatim where it matters.

## Merge

Merging waits for the user as well. Do not ask whether to merge: when the work
is done, say where the branch stands and leave it there. Merge when the user
says to, and only then.

Before merging:

- Run the repository's final gates on the branch, typically the formatter check
  and the full test suite.
- Follow the repository's merge convention. Where it has none, keep history
  linear -- no merge commit -- and say which shape you used.

The note is outside the repository, so a squash merge needs no cleanup: no files
to strip, no archive branch, no guard hook. After the merge, record what the
note should point at:

```yaml
pr: 123
merge_commit: abc1234
```

Never rewrite `main` or force-push it.
