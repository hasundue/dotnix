# dotnix

NixOS + Home Manager flake for user `hasundue`. ~45 Nix modules, custom
packages, overlays, and dev shells.

You, the coding agent reading this file, and the system you and the user are
operating on, are likely configured via Nix in this very repository. When asked
to configure something (including yourself), work on this repository.

## Git Conventions

### Branches

Do not commit directly to `main` unless explicitly asked.

Before creating a worktree from `~/dotnix`, fetch `origin` and verify the
checkout is on `main` and `git rev-list --left-right --count
origin/main...HEAD` prints two zeros. Otherwise, stop and report. Re-check the
branch and sync immediately before creating the worktree.

A new worktree starts from committed state; uncommitted changes remain in the
primary checkout. Do not stash, reset, or otherwise transfer them unless asked.

### Worktrees

Make code changes in a linked worktree, not in the primary checkout at
`~/dotnix`. Do not create a branch in place there with `git switch -c` or
`git checkout -b`; use `wt switch --create` below.

`wt list` reports where the current directory sits; when it is already a
worktree such as `~/dotnix.<branch>`, keep working there and do not nest
another one.

```bash
wt switch --create <branch>   # from ~/dotnix, creates ~/dotnix.<branch>
```

### Live configuration

A feature's configuration is live when `dotnix.live.<name>.enable` links it to
the checkout selected by activation (currently Pi's
`configs/home/pi/agent`). Before editing those linked files, activating from a
worktree, or removing a worktree, read [the live configuration
guide](docs/live-configuration.md). Removal relies on the approved Worktrunk
`pre-remove` hook; do not bypass its approval.

A dirty `main` is acceptable. Do not commit or push to `main` from that state:
a mistake would then only be fixable destructively.

### Git workflow

Before committing, amending, rebasing, pushing, merging, deleting a source
branch, or removing a worktree, read and follow [the project-local Git workflow
skill](.agents/skills/git-workflow/SKILL.md). Follow its approval,
validation, and stop conditions; if the skill is unavailable or a precondition
is unmet, stop and ask rather than proceeding.

## Validate

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

## Nix Queries

Resolve NixOS and home-manager questions against this flake's pinned inputs,
not the network. Both sources are already in the store:

```bash
nix eval --raw .#nixosConfigurations.x1carbon.pkgs.path        # pinned nixpkgs
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.home-manager.outPath'
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

The `nixos-*` apps accept passthrough flags (`--impure`, `--show-trace`, etc.).
They pipe output through `nom` when stdout is a TTY, and skip it when non-TTY
for minimal output. `NOM_DISABLE` forces raw output even in a TTY:

```bash
NOM_DISABLE=1 nix run .#nixos-build
NOM_DISABLE=1 nix run .#nixos-switch
```

## Apply

Before running any activation command (`home-switch`, `nixos-test`,
`nixos-switch`, `nixos-boot`, or `home-live`), read and follow the
[Nix activation skill](.agents/skills/nix-activation/SKILL.md). This includes
commands mentioned in the build guidance above. For build-only validation, use
the build commands there.
