# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS configuration repository using Nix flakes for declarative system and user environment management. The configuration supports two hosts: `x1carbon` (ThinkPad laptop) and `nixos` (NixOS-WSL).

## Common Commands

### System Management
- `nrs` - Rebuild and switch to new configuration: `sudo nixos-rebuild switch --flake . |& nom`
- `nrb` - Rebuild for next boot: `sudo nixos-rebuild boot --flake . |& nom`  
- `nrt` - Test configuration temporarily: `sudo nixos-rebuild test --flake . |& nom`

### Flake Operations
- `nfc` - Check flake validity: `nix flake check`
- `nfs` - Show flake outputs: `nix flake show`
- `nfu` - Update all flake inputs: `nix flake update`
- `nd` - Enter development shell: `nom develop`

### Development Workflow
```bash
# Make configuration changes
nfc                           # Validate changes
nrt                          # Test temporarily
nrs                          # Apply permanently
```

### Available Development Shells
Enter with `nix develop .#<shell-name>`:
- `default` - General development with common tools
- `rust` - Rust development with cargo-cross
- `python` - Python development environment
- `deno` - Deno/TypeScript development
- `playwright` - Web testing with Playwright
- `nix` - Nix development tools

## Architecture

### Directory Structure
- `home/` - Home Manager user configurations (applications, desktop, shells)
- `hosts/` - Host-specific system configurations (x1carbon, wsl)
- `nixos/` - System-level NixOS modules (base system, desktop)
- `shells/` - Development environment definitions
- `secrets/` - Encrypted secrets managed by Agenix
- `overlays/` - Custom package overlays and helper functions

### Key Architectural Patterns

**Modular Configuration**: Clear separation between system (`nixos/`), user (`home/`), and host-specific (`hosts/`) configurations. Desktop configurations are optional imports.

**Flake Structure**: Uses modern Nix flakes with proper input management. All inputs follow nixpkgs for consistency.

**Development Isolation**: Development shells are completely separate from system configuration, allowing clean development environments.

**Home Manager Integration**: User environment and applications managed declaratively through Home Manager with shared modules.

### Configuration Flow
1. `flake.nix` defines inputs and system configurations
2. Host configurations (`hosts/*/default.nix`) import base modules and add customizations
3. NixOS modules (`nixos/`) provide system-level configuration
4. Home Manager modules (`home/`) configure user environment
5. Overlays provide helper functions and custom packages

### Secret Management
Uses Agenix for encrypted secrets. API keys and credentials stored in `secrets/` directory and decrypted at activation time.

### Theming
Stylix provides system-wide theming with Kanagawa color scheme. Theme applies to terminal, editor, desktop applications, and window manager.

## Development Guidelines

### Making Configuration Changes
1. Always validate with `nfc` before rebuilding
2. Test changes with `nrt` before permanent application
3. Use appropriate development shells for language-specific work
4. Keep host-specific configurations in respective `hosts/` directories

### Adding New Applications
- System applications: Add to appropriate `nixos/` module
- User applications: Add to `home/` modules
- Development tools: Consider adding to relevant development shell

### Managing Secrets
Use Agenix for any sensitive configuration. Add new secrets to `secrets/secrets.nix` and reference in configurations.