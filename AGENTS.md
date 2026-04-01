# AGENTS.md

This file provides guidance for AI agents working with this repository.

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

## Validation

Prefer LSP evaluation. When LSP is insufficient, target the exact path:

```bash
# NixOS
nix eval .#nixosConfigurations.x1carbon.config.services.openssh

# Home Manager
nix eval .#homeConfigurations."hasundue@x1carbon".config.wayland.windowManager.niri
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
