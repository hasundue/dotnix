# AGENTS.md

This file provides guidance for AI agents working with this repository.

> **Note**: You, the coding agent reading this file, are likely configured via
> Nix in this very repository. See `configs/home/<your-name>/` for user-wide
> settings and `modules/home/<your-name>/` for the Home Manager module.

## Overview

NixOS configuration flake for user `hasundue`. Hosts:

- `x1carbon` — ThinkPad X1 Carbon (x86_64-linux, desktop)
- `nixos` — NixOS-WSL (x86_64-linux, headless)

## Directory Structure

```
configs/
  hosts/       # Host-specific NixOS modules (x1carbon, wsl)
  nixos/       # Shared NixOS modules
  home/        # Home Manager modules (shared + desktop/)
  stylix.nix   # Theming shared by NixOS and Home Manager
overlays/      # Nixpkgs overlays (see Architecture)
packages/      # Custom packages defined with callPackage
shells/        # Dev shells (each subdir is a flake devShell)
templates/     # Flake templates
```

## Code Style

- **Module parameters**: `{ pkgs, lib, config, ... }:` — keep this order
- **Imports**: declare first, separated by a blank line from other attributes
- **`let…in`**: define before the main attribute set
- **Indentation**: 2 spaces; multi-line attribute sets and lists
- **`with pkgs;`**: acceptable in package list expressions
- **Comments**: `#` only where the intent is non-obvious

## Architecture

- **Input isolation**: flake inputs are declared only in `flake.nix` and exposed
  to modules exclusively via overlays; modules never receive `inputs`
- **Overlays** (`overlays/`):
  - `default.nix` — custom local overlays auto-imported by `flake.nix`
  - `pristine.nix` — packages sourced from flake inputs (e.g. firefox-addons)
  - `temporal.nix` — temporary overrides from `nixpkgs-master`; remove entries
    once the fix reaches `nixpkgs-unstable`
- **Packages** (`packages/`): standalone packages built with `callPackage`,
  merged into `pkgs` via `pkgsFor` in `flake.nix`

## Commit Convention

```
scope: imperative summary
```

Always use a scope. Imperative mood, no period at the end.

Derive scope from the **leaf** of the changed config's directory path:

| Changed path                       | Scope    |
| ---------------------------------- | -------- |
| `configs/home/pi/default.nix`      | `pi`     |
| `configs/home/niri/default.nix`    | `niri`   |
| `configs/nixos/waybar/default.nix` | `waybar` |

Prepend the parent directory _only_ when the same config name exists under a
different parent (e.g. both `configs/home/waybar` and `configs/nixos/waybar`
exist → use `home/waybar` and `nixos/waybar`).

Fixed scopes (exceptions):
- `agents:` — AGENTS.md
- `flake:` — flake.nix, flake inputs

## Validate

Quick-check any config option with `nix eval` instead of a full build:

```bash
nix eval .#nixosConfigurations.<hostname>.config.<option.path>
nix eval .#homeConfigurations."<user>@<hostname>".config.<option.path>
```

Examples:

```bash
# NixOS: SSH config
nix eval .#nixosConfigurations.x1carbon.config.services.openssh

# Home Manager: window manager
nix eval .#homeConfigurations."hasundue@x1carbon".config.wayland.windowManager.niri
```

Use the right hostname (`x1carbon` or `nixos`) depending on what you're
validating. The output is the config value in Nix notation.

### Build

```bash
# NixOS
nix run .#nixos-build

# Home Manager
nix run .#home-build
```

Build apps accept passthrough flags (`--impure`, `--show-trace`, etc.). They
also auto-detect TTY: if non-TTY they skip `nom` for minimal output. Force raw
even in TTY:

```bash
NOM_DISABLE=1 nix run .#nixos-build
```

### Apply (Home Manager only)

```bash
nix run .#home-switch
```

Requires a prior build (checks for `result-home` symlink and fails with a clear
message if missing).
