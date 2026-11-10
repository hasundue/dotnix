# dotnix

NixOS + Home Manager flake for user `hasundue`. ~45 Nix modules, custom
packages, overlays, and dev shells.

You, the coding agent reading this file, and the system you and the user are
operating on, are likely configured via Nix in this very repository. When asked
to configure something (including yourself), work on this repository.

## Worktrees

Make code changes in a worktree, not in the primary checkout at `~/dotnix`.
`wt list` reports where the current directory sits; when it is already a
worktree such as `~/dotnix.<branch>`, keep working there and do not nest
another one.

```bash
wt switch --create <branch>   # from ~/dotnix, creates ~/dotnix.<branch>
```

Live configuration is the exception. Where `dotnix.live.<name>.enable` is set
(`pi` today, with `~/dotnix.live.pi` resolving to
`~/dotnix/configs/home/pi/agent`), the running system reads the files straight
out of that checkout, so a worktree copy changes nothing until it merges. Make
those edits in `~/dotnix` itself, then return to a worktree for the rest.

## Commit Convention

```
scope: imperative summary
```

Always use a scope. Imperative mood, no period at the end.

Derive scope from the **leaf** of the changed config's directory path:

| Changed path                        | Scope      |
| ----------------------------------- | ---------- |
| `configs/home/opencode/default.nix` | `opencode` |
| `configs/home/niri/default.nix`     | `niri`     |
| `configs/nixos/waybar/default.nix`  | `waybar`   |

Prepend the parent directory _only_ when the same config name exists under a
different parent (e.g. both `configs/home/waybar` and `configs/nixos/waybar`
exist → use `home/waybar` and `nixos/waybar`).

### Fixed scopes

- `agents:` — AGENTS.md
- `flake:` — flake.nix, flake inputs

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

## Apply (NixOS)

Wraps `nixos-rebuild` and manages the system profile:

```bash
nix run .#nixos-test    # Test without making it the default
nix run .#nixos-switch  # Apply permanently
nix run .#nixos-boot    # Set the boot entry for next reboot
```

Run them as a normal user: sudo is requested only for activation, so the
password is asked at most once (not at all with a cached sudo timestamp).
Prefixing with `sudo` also works without a second prompt.

## Apply (Home Manager)

Builds first and activates without sudo:

```bash
nix run .#home-switch
```

It runs `home-manager switch --flake .#<user>@<host>`, the same command the
`hms` alias uses. `nix run .#home-build` still exists for building
`./result-home` without activating anything. Flake arguments (`--impure`,
`--refresh`, etc.) go straight through to `home-manager`.
