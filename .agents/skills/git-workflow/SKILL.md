---
name: git-workflow
description: >
  Apply project-local Git conventions for commit messages, pushing, rebasing,
  merging into main, and branch or worktree cleanup. Use before committing,
  rewriting history, pushing, merging, or removing a source branch or worktree.
---

# Git workflow

These procedures supplement the always-on branch and worktree rules in
`AGENTS.md`; they do not override them. In particular, do not commit directly
to `main` unless explicitly asked. Follow every approval gate below. Stop and
ask if a precondition fails or the repository state differs from the plan.

## Formatter hook recovery

If a pre-commit hook applies formatting and aborts the commit because files
changed:

1. Inspect the complete staged and unstaged diffs.
2. If every change is formatting-only and limited to files already intended for
   the commit, stage those paths explicitly and retry the commit. Let the hooks run
   again; proceed only when they pass. This routine retry does not need additional
   user approval.
3. If the hook made unexpected or non-formatting changes, another check failed,
   or unrelated edits could be included, stop and ask before recovery. Do not use
   `git add -A` for this retry.

## Merging

Before merging, inspect the branch. If its commits already follow
[Granularity](#granularity) and use appropriate scopes, leave them unchanged
and run relevant validation on the branch tip. Otherwise, propose the
`main`-commit grouping, scopes, and validation; wait for the user's approval
before rewriting. After approval, rebase onto the current `main` and reorganize
checkpoints by outcome in the source branch's checkout. For one outcome, use
`git reset --soft main` and recommit. For multiple outcomes, use
`git reset --mixed main`, then stage and commit each outcome by path or patch.
Run the proposed validation on the branch tip. If the approved rewrite changes
a branch on `origin`, update it with `git push --force-with-lease` after
validation.

Before a local merge, verify
`git -C ~/dotnix merge-base --is-ancestor main <branch>` succeeds before
switching the primary checkout to `main`. If it does not, stop and propose a
rebase onto current `main`; wait for approval before rewriting.

Merge and push from the primary checkout so live changes are backed up at
once:

```bash
git -C ~/dotnix switch main &&
  git -C ~/dotnix merge --ff-only <branch> &&
  git -C ~/dotnix push
```

After fetching `origin`, merge the branch into local `main` unless `<branch>`
is already an ancestor of `origin/main`. If it is, verify local `main` is also
an ancestor of `origin/main` before switching the live checkout. If not, stop
and ask; otherwise fast-forward local `main`.

After the local merge or remote fast-forward succeeds, refresh origin's refs.
Delete the source remote branch only if its current tip is contained in
`origin/main`; skip deletion if it is already absent, and stop and ask if it is
not contained. Then remove the local worktree or branch.

If validation fails, do not merge; stop and ask. If a Git operation fails or
the repository state differs from the plan, stop and ask before attempting a
recovery, except for the routine formatter-hook retry described in
[Formatter hook recovery](#formatter-hook-recovery).

## Commit messages and scopes

Use this format:

```
scope: imperative summary
```

Always use a scope. Use imperative mood and no period at the end.

The scope is the leaf of the primary config's directory, even when the outcome
also requires changes elsewhere:

| Changed path                                     | Scope          |
| ------------------------------------------------ | -------------- |
| `configs/home/opencode/default.nix`              | `opencode`     |
| `configs/home/niri/default.nix`                  | `niri`         |
| `configs/nixos/waybar/default.nix`               | `waybar`       |
| `configs/home/pi/agent/skills/subagent/SKILL.md` | `pi/subagent`  |
| `.agents/skills/git-workflow/SKILL.md`           | `git-workflow` |

Add one parent when the leaf alone does not identify the config:

- The same config exists under several parents: `configs/home/waybar` and
  `configs/nixos/waybar` → `home/waybar` and `nixos/waybar`.
- The config lives inside a feature's own data directory, where the leaf is a
  skill, extension, or prompt that only makes sense under that feature:
  `configs/home/pi/agent/skills/subagent/` → `pi/subagent`.

Configs that merely sit in directories sharing a name keep the leaf
(`configs/home/desktop` and `configs/nixos/desktop` → `desktop:`). Use
`treewide:` for a cohesive outcome that spans multiple config scopes without a
clear primary config.

### Fixed scopes

- `agents:` — `AGENTS.md`
- `chore:` — files that belong to no feature: `.gitignore`, `.config/wt.toml`,
  `.github/`
- `flake:` — `flake.nix`, flake inputs

### Granularity

#### Commits that land on `main`

Use one commit per distinct, independently meaningful outcome. Keep all
changes needed for one outcome together, even when they touch multiple files
or configs; keep distinct outcomes in separate commits. Each commit must leave
the project coherent. Run validation on the branch tip, not at every commit
boundary.

#### Working-branch checkpoints

Make smaller checkpoint commits as useful while working. Checkpoints may be
incomplete or temporarily leave the project failing validation. If the branch
needs restructuring, reorganize checkpoints into one or more commits for
`main`: combine checkpoints for the same outcome, and preserve separate
commits for distinct outcomes.

## Pushing

A commit on a branch is pushed in the same step: `git commit ... && git push`.
An unpushed commit is unfinished work, not a backup. `push.autoSetupRemote` is
already set, so a new branch needs no `-u`.

Do not rewrite a pushed commit on a working branch, and do not amend it to fold
in a later fix: add a commit. The branch is squashed on merge anyway, and a
rewrite turns the work into one opaque diff that the user can no longer follow.
For an explicitly authorized change on `main`, add a fix commit. The only
rewrite is the approved reorganization under [Merging](#merging), with
`--force-with-lease`.
