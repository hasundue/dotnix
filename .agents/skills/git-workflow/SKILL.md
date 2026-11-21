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
[Granularity](#granularity) and use appropriate scopes, leave them unchanged and
run relevant validation on the branch tip. Otherwise, propose the `main`-commit
grouping, scopes, and validation; wait for the user's approval before rewriting.
After approval, rebase onto the current `main` and reorganize checkpoints by
outcome in the source branch's checkout, then run the proposed validation on
the branch tip. Do not push the reorganized branch to `origin`. After reorganizing,
do not run `git push` or `git pull` on the working branch; go straight to validation
and merge.

Run the merge with Worktrunk in the source branch's checkout, so the local
reorganized tip is what gets merged.

When the source worktree owns the live tree, treat its removal and the
`pre-remove` rehoming of live links to the primary checkout as part of the
merge. Read the live configuration guide before removal and do not bypass the
hook. Keep the worktree with `--no-remove` only when the user asked to keep it
or explicitly deferred cleanup.

Keep the source remote branch after a merge as a checkpoint archive; do not
delete it. Rebased commits are never pushed, so the archive is not the merged
result. Branch from `main`. Removal is defined in
`.github/workflows/archive-cleanup.yml`.

If validation fails, do not merge; stop and ask.

## Commit messages and scopes

Use this format:

```
scope: imperative summary
```

Always use a scope. Use imperative mood and no period at the end.

The scope names the config that changed — normally the leaf of the primary
config's directory — even when the outcome also requires changes elsewhere:

| Changed path                                           | Scope                   |
| ------------------------------------------------------ | ----------------------- |
| `configs/home/niri/default.nix`                        | `niri`                  |
| `configs/nixos/waybar/default.nix`                     | `waybar`                |
| `configs/home/pi/agent/skills/skiff/SKILL.md`          | `pi/skiff`              |
| `configs/home/pi/agent/AGENTS.md`                      | `pi`                    |
| `.agents/skills/git-workflow/SKILL.md`                 | `agents/git-workflow`   |
| `.agents/skills/nix-activation/SKILL.md`               | `agents/nix-activation` |
| `configs/home/default.nix`, the `programs.tmux` block  | `tmux`                  |
| `configs/home/default.nix`, imports or `home.packages` | `home`                  |

When the primary config has no directory of its own — it lives as one block in a
shared file such as `configs/home/default.nix` — name the block's module instead
of the file's parent directory: the `programs.tmux` block is `tmux`, not `home`.
Name the parent (`home`) only when the change concerns the whole file: imports,
`home.packages`, or several blocks at once (`treewide:` may fit instead).

Add one parent when the leaf alone does not identify the config:

- The same config exists under several parents: `configs/home/waybar` and
  `configs/nixos/waybar` → `home/waybar` and `nixos/waybar`.
- The config lives inside a feature's own data directory, where the leaf is a
  skill, extension, or prompt that only makes sense under that feature:
  `configs/home/pi/agent/skills/skiff/` → `pi/skiff`.

Configs that merely sit in directories sharing a name keep the leaf
(`configs/home/desktop` and `configs/nixos/desktop` → `desktop:`). Use
`treewide:` for a cohesive outcome that spans multiple config scopes without a
clear primary config.

### Fixed scopes

- `agents:` — the root `AGENTS.md` and `.agents/`
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
in a later fix: add a commit. A squash merge leaves `main` with one opaque diff,
and the remote branch keeps the last pushed checkpoint sequence as its archive;
rewriting pushed commits would desynchronize that archive from what was reviewed.
For an explicitly authorized change on `main`, add a fix commit. The only
exception is the approved local reorganization under [Merging](#merging); never
push its result.
