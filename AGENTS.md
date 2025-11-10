# AGENTS.md

This file provides guidance for AI agents working with this repository.

## Repository Type
NixOS configuration repository using Nix flakes for declarative system and home management.

## Validation

**IMPORTANT**: Always target the minimal subset of configuration that covers your changes. Avoid full checks unless explicitly requested.

### Specific Attribute Validation (Recommended)
Target the exact configuration path you're modifying:
- **NixOS**: `nix eval .#nixosConfigurations.<host>.config.<path>`
  - Example: `.services.openssh` for openssh changes
- **Home**: `nix eval .#homeConfigurations.<user@host>.config.<path>`
  - Example: `.wayland.windowManager.niri` for niri changes

### Full Configuration Validation
Only use when changes affect entire config or when explicitly requested:
- **NixOS**: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel` (e.g., `x1carbon`)
- **Home**: `nix eval .#homeConfigurations.<user@host>.activationPackage` (e.g., `hasundue@x1carbon`)
- **Entire flake**: `nix flake check` (very slow - validates all outputs, checks, packages, overlays, etc.)

## Commands
- **Update Inputs**: `nix flake update` (update all flake inputs)
- **Note**: Do NOT run `nixos-rebuild` commands - user will apply changes manually

## Code Style
- **Imports**: List imports first, separate by blank line before other attributes
- **Module Parameters**: Use `{ pkgs, lib, config, ... }:` pattern; order consistently
- **Let Bindings**: Use `let...in` for local variables, define before main attribute set
- **Attribute Sets**: Use multi-line format with proper indentation (2 spaces)
- **Lists**: Use `[ ]` for simple lists, multi-line for complex items with consistent indentation
- **With Statements**: Acceptable for `with pkgs;` in package lists
- **Comments**: Use `#` for inline comments, explain non-obvious configuration decisions

## Architecture
- **Input Isolation**: Flake inputs stay in `flake.nix`, exposed via overlays; modules never receive `inputs` directly
- **Separation**: System configs in `nixos/`, user configs in `home/`, host-specific in `hosts/`
- **Overlays**: Add external packages/functions via overlays in `overlays/`, access through `pkgs.*`
