# AGENTS.md

This file provides guidance for AI agents working with this repository.

## Repository Type

NixOS configuration repository using Nix flakes.

## Essential Commands

- `nrs` - Rebuild and switch: `sudo nixos-rebuild switch --flake .`
- `nrt` - Test configuration: `sudo nixos-rebuild test --flake .`
- `nfc` - Check flake: `nix flake check`

## Important Rules

- **Always ask permission** before running system management commands (`nrs`, `nrb`, `nrt`)
- Pre-commit hooks handle formatting automatically - don't run `nix fmt` manually

## Additional Documentation

See `README.md` for architecture, commands, and development guidelines.
