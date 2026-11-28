# dotnix

NixOS + Home Manager flake for user `hasundue`. ~45 Nix modules, custom
packages, overlays, and dev shells.

You, the coding agent reading this file, and the system you and the user are
operating on, are likely configured via Nix in this very repository. When asked
to configure something (including yourself), work on this repository.

## Git Conventions

### Branches

Do not commit directly to `main` unless explicitly asked.

Do not stash, reset, or otherwise transfer uncommitted changes from the primary
checkout unless asked.

### Worktrees

Make code changes in a linked worktree, not in the primary checkout at
`~/dotnix`. Do not create a branch in place there with `git switch -c` or
`git checkout -b`; create the worktree with Worktrunk.

When the current directory is already a worktree such as `~/dotnix.<branch>`,
keep working there and do not nest another one.

A dirty `main` is acceptable. Do not commit or push to `main` from that state:
a mistake would then only be fixable destructively.

### Git workflow

Before committing, amending, rebasing, pushing, merging, deleting a source
branch, or removing a worktree, read and follow [the project-local Git workflow
skill](.agents/skills/git-workflow/SKILL.md). Follow its approval,
validation, and stop conditions; if the skill is unavailable or a precondition
is unmet, stop and ask rather than proceeding.

### Task spec

A task spec is `SPEC.md` at the root of the branch or worktree carrying the
work. A request for `SPEC.md` is a request for a worktree.

## Validate

Format with `nix fmt`, which uses the flake's formatter without entering a dev
shell.

Quick-check any config option with `nix eval` instead of a full build:

```bash
nix eval .#nixosConfigurations.<hostname>.config.<option.path>
nix eval .#homeConfigurations."<user>@<hostname>".config.<option.path>
```

### Examples

```bash
# NixOS: SSH config
nix eval .#nixosConfigurations.x1carbon.config.services.openssh

# Home Manager: window manager
nix eval .#homeConfigurations."hasundue@x1carbon".config.wayland.windowManager.niri
```

Use the right hostname (`x1carbon` or `higame`) depending on what you're
validating. The output is the config value in Nix notation.

Do not pass `--impure` when evaluating this repository's flake; impure runs
have poor cache reuse here and can exhaust available memory. This rule also
applies to the Nix commands in this file and in the referenced build and
activation skills, including `nix eval` and the `nixos-*` apps' passthrough
flags. Use pure flake references such as `nix eval .#...`; if a flake query
fails in pure mode, stop and ask rather than retrying with `--impure`.

## Nix Queries

Resolve NixOS and home-manager questions against this flake's pinned inputs,
not the network. Both sources are already in the store:

```bash
nix eval --raw .#nixosConfigurations.x1carbon.pkgs.path  # pinned nixpkgs
nix flake archive --json --dry-run .                    # pinned input source paths
```

- Does package X exist?
  `nix eval --raw .#nixosConfigurations.x1carbon.pkgs.X.pname`
- Where is a module or option defined? `grep` the pinned sources above.
- What is option X set to? `nix eval .#nixosConfigurations.x1carbon.config.X`

Do not scan `/nix/store` or reach for `nixpkgs search` to answer these; the
pinned tree answers exactly for the revision being built.

## Build and Apply

For build-only validation, read and follow the
[Nix build skill](.agents/skills/nix-build/SKILL.md). A change under
`configs/home/` only can usually be checked with `home-switch`, which builds and
activates without sudo; it is an activation command.

Before running any activation command (`home-switch`, `nixos-test`,
`nixos-switch`, or `nixos-boot`), read and follow the
[Nix activation skill](.agents/skills/nix-activation/SKILL.md). The user runs
commands that need sudo; verify the result afterwards and do not ask for a sudo
password or add non-interactive elevation.
