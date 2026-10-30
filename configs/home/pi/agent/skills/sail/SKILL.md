---
name: sail
description: >
  Execute an agreed spec. Use after a spec gate such as keel, or whenever
  ISSUE.md and SPEC.md already define the problem, acceptance criteria, and
  confirmation. Works through each criterion with its verify step, updates the
  spec before changing scope, stops on blockers instead of guessing, and reports
  evidence per criterion. Use when the user says "execute the spec", "implement
  SPEC.md", "start the work", or hands off an agreed ISSUE.md/SPEC.md.
---

# Sail

Keel lays the spec; sail executes it. The agreement is already made. Do not
reopen the interview, cut a new branch, or rewrite the problem unless the spec
is actually broken.

## Invariants

1. **Read `ISSUE.md` and `SPEC.md` before touching code.**
2. **Every acceptance criterion ends with evidence or an explicit unmet
   report.**
3. **Scope moves in `SPEC.md` first, then gets re-confirmed.**
4. **A blocker is written down and raised, never silently absorbed.**

Everything else -- implementation order, commits, test commands -- follows the
repo and the spec.

## Start

Read both files. If either is missing or empty, stop and ask. If the spec
records confirmation (for example `## Confirmed`), check it; if there is no
explicit sign-off, ask whether the spec is agreed before implementing.

Check the current branch and working tree so you know what you are changing. Do
not push, rewrite history, or discard unrelated work unless the spec or the user
asks for it.

If a criterion has no `verify:`, that is a spec defect. Ask for it to be made
checkable rather than inventing your own success condition.

## Execute

Work through the acceptance criteria, not through a feeling of doneness. Use
each criterion's `verify:` to decide what to run or inspect.

- Keep changes inside the spec's scope.
- If a criterion is already satisfied, record the evidence instead of changing
  code to look busy.
- Follow the repository's own rules for tests, formatting, and commits.
- If the spec is silent on a local implementation detail, use judgment and note
  it; silence is not permission to change the agreed outcome.

## Scope changes and blockers

When reality contradicts the spec -- a constraint was wrong, a step is
impossible, a criterion is incomplete, or the work needs to grow -- update
`SPEC.md` (and `ISSUE.md` if the problem changed) before acting, then ask for
re-confirmation. Do not drift silently.

Stop instead of grinding when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the spec -- stop;
- a genuine trade-off needs a human decision -- stop.

Write the situation under `## Blocker` in `SPEC.md`: what was tried, what
happened, the likely cause, and the options you see. Then ask. A stop without a
written trace is a failed handoff.

## Verify and close

Walk the acceptance criteria one by one and report evidence per item: the
command and its result, or what you observed and where. Unmet criteria are
reported as unmet, not renegotiated after the fact.

Do not call the work done because the diff looks plausible. The criteria decide.

What happens to `ISSUE.md`, `SPEC.md`, and `## Blocker` notes is the user's
call, case by case: delete them before merging, leave them on the branch, or
keep them deliberately. Ask; do not archive, move, or delete on your own.

End with a compact report: what changed, which criteria passed with what
evidence, what is unmet, and what still needs a decision. The next action is the
user's.

## Merge after confirmation

Merge only after the user has confirmed the result. Passing tests are evidence,
not permission to merge.

Before merging:

- Run the repository's final gates on the branch, typically the formatter check
  and the full test suite.
- Confirm what happens to `ISSUE.md` and `SPEC.md`. If they should not land on
  `main`, archive the original branch or tag before creating the squashed
  history, then remove the files from the merge commit.
- Follow the repository's merge convention. If there is none, ask whether the
  user wants a single linear commit, a merge commit, or a platform squash merge.
  Do not choose the history shape silently.

A safe default when the user wants one linear commit and the spec should stay
out of `main`:

```bash
# 1. Archive the original branch (or create a tag).
git branch archive/<slug> <branch>
git push origin archive/<slug>          # if it must survive outside the clone

# 2. Squash the work on a temporary branch from main.
git switch main
git switch -c squash/<slug>
git merge --squash <branch>

# 3. Drop the spec files from the squashed tree if agreed.
git rm ISSUE.md SPEC.md

# 4. Commit with the repository's message style.
git commit -m "<repo-style message>"

# 5. Re-run the final gates on the squashed commit, then merge.
git switch main
git merge --ff-only squash/<slug>

# 6. Push only if the user asked.
git push origin main

# 7. Clean up, keeping the archive if it holds the only spec copy.
git branch -d squash/<slug>
```

If the repository uses pull requests, prefer the platform's squash merge and
keep the archive branch on the remote. If the user wants a merge commit, use
`--no-ff` instead. Never rewrite `main` or force-push it.
