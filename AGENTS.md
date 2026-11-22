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
applies to the Nix commands and examples in the sections below, including
`nix eval` and the `nixos-*` apps' passthrough flags. Use pure flake references
such as `nix eval .#...`; if a flake query fails in pure mode, stop and ask
rather than retrying with `--impure`.

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

## Build

```bash
# NixOS + home-manager together (wraps nixos-rebuild; leaves ./result)
nix run .#nixos-build

# Home Manager only (standalone generation; leaves ./result-home)
nix run .#home-build
```

Which pair to use depends on what changed. A change under `configs/home/` only
needs `nix run .#home-switch`, which builds the standalone `homeConfigurations`
against the same `pkgs` and activates without sudo. Anything else
(`configs/hosts/`, `configs/nixos/`, the flake itself) needs `nixos-*`, which
rebuilds home-manager too. Both are safe, but the standalone configuration
installs packages into the home-manager profile rather than the per-user system
profile that `useUserPackages` uses, so for a change that touches packages
rather than config files, trust `nixos-*`.

The `nixos-*` apps accept passthrough flags such as `--show-trace`. They pipe
output through `nom` when stdout is a TTY, and skip it when non-TTY for minimal
output.
`NOM_DISABLE` forces raw output even in a TTY:

```bash
NOM_DISABLE=1 nix run .#nixos-build
NOM_DISABLE=1 nix run .#nixos-switch
```

## Apply

Before running any activation command (`home-switch`, `nixos-test`,
`nixos-switch`, or `nixos-boot`), read and follow the
[Nix activation skill](.agents/skills/nix-activation/SKILL.md). This includes
commands mentioned in the build guidance above. For build-only validation, use
the build commands there.

NixOS activation commands (`nixos-test`, `nixos-switch`, and `nixos-boot`) need
sudo, so the user runs them; after each activation, verify the resulting state
as far as possible here. Use `home-switch` and the build-only commands for
checks that do not need sudo, and do not ask for a sudo password or add
non-interactive elevation.
