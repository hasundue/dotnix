# AGENTS.md

This file provides guidance for AI agents working with this repository.

## Repository Type
NixOS configuration repository using Nix flakes for declarative system and home management.

## Commands
- **Validate**: `nix flake check` (validate flake structure and configurations)
- **Format Code**: `treefmt` (via `nix develop` - runs nixfmt on all .nix files)
- **Update Inputs**: `nix flake update` (update all flake inputs)
- **Note**: Do NOT run `nixos-rebuild` commands - user will apply changes manually

## Code Style
- **Formatter**: Use `nixfmt` for all Nix files (enforced via git pre-commit hooks)
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
