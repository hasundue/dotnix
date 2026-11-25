# Merge

Read this only when the user says to merge.

Merging waits for the user's word. Do not ask whether to merge: when the work is
done, say where the branch stands and leave it there. A spec marked `stale` has
no outcome for `main`; do not merge that branch. If the user asks anyway, stop
and ask where the context belongs.

Before merging:

- Run the repository's final gates on the branch, typically the formatter check
  and the full test suite.
- Reorganize the branch into outcome commits by the repository's merge
  procedure, which `AGENTS.md` points to. The user approves the reorganized form
  before the merge. Outcome commits carry the reason for the change in their
  body, and the context recorded in agreement-change commit bodies -- why the
  agreement moved, or context moved out of a cleared blocker -- in the outcome
  commit that keeps the change. A checkpoint body alone does not survive
  reorganization. If any of
  this cannot be carried, stop and ask where the context belongs. If the
  repository has no merge procedure, stop and ask.
- The target must receive no written spec. Use the carrier's path from the
  session; check `git ls-tree --name-only HEAD -- <path>` and the same command
  on `<target>`. If either prints anything, stop and ask, because that file is
  not this task's. Delete any untracked carrier left in the worktree, and read
  `git status --short`: it must be clean.
- Follow the repository's merge convention. Where it has none, keep history
  linear -- no merge commit -- and say which shape you used.

The reorganized commits are what `main` receives: outcome commits that carry the
problem, and no spec file. Record the outcome in conversation and commit
messages. Never rewrite `main` or force-push it.
