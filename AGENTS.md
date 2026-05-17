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
.agents/
  skills/      # Repo-local agent skills (e.g., config-agent-skill)
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

## Validation

Prefer LSP evaluation. When LSP is insufficient, target the exact path:

```bash
# NixOS
nix eval .#nixosConfigurations.x1carbon.config.services.openssh

# Home Manager
nix eval .#homeConfigurations."hasundue@x1carbon".config.wayland.windowManager.niri
```

## Flake Apps

Build/activate-split apps (build runs `nix build` without sudo, activate
applies the result):

```bash
# NixOS (build then activate with sudo)
nix run .#nixos-build
sudo nix run .#nixos-switch  # or nixos-test, nixos-boot

# Home Manager (no sudo needed)
nix run .#home-build
nix run .#home-switch
```

Build apps accept passthrough flags (`--impure`, `--show-trace`, etc.).
Activate apps require a prior build (they check for `result-nixos` or
`result-home` symlinks and fail with a clear message if missing).

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
