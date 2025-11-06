# hasundue's NixOS Configuration

Personal NixOS system configuration using Nix flakes for declarative system and user environment management.

## System Configurations

- **x1carbon** - ThinkPad X1 Carbon laptop configuration
- **nixos** - NixOS-WSL setup for Windows Subsystem for Linux

## Features

- **Home Manager** - User environment and application management
- **Stylix** - System-wide theming with Kanagawa color scheme
- **Agenix** - Encrypted secrets management
- **Custom Neovim** - Personal Neovim configuration
- **Development Shells** - Ready-to-use environments for various languages
- **Desktop Environment** - Sway compositor with Waybar and supporting tools
- **Flake Templates** - Reusable project templates with development tooling

## Structure

- `home/` - User environment configurations (applications, desktop settings)
- `hosts/` - Host-specific system configurations
- `nixos/` - System-level NixOS modules
- `shells/` - Development environment shells (Python, Rust, Deno, etc.)
- `secrets/` - Encrypted secrets for API keys and credentials
- `templates/` - Flake templates for new projects

## Common Commands

### System Management

- `nrs` - Rebuild and switch: `sudo nixos-rebuild switch --flake .`
- `nrb` - Rebuild for next boot: `sudo nixos-rebuild boot --flake .`
- `nrt` - Test configuration: `sudo nixos-rebuild test --flake .`

### Flake Operations

- `nfc` - Check flake: `nix flake check`
- `nfs` - Show flake outputs: `nix flake show`
- `nfu` - Update flake inputs: `nix flake update`
- `nd` - Enter development shell: `nix develop`

### Development Workflow

```bash
# Make configuration changes
nfc                           # Validate changes
nrt                          # Test temporarily
nrs                          # Apply permanently
```

## Development Shells

Enter with `nix develop .#<shell-name>`:
- `default` - General development with common tools
- `rust` - Rust development with cargo-cross
- `python` - Python development environment
- `deno` - Deno/TypeScript development
- `playwright` - Web testing with Playwright
- `nix` - Nix development tools

## Templates

Initialize a new project with the default template:
```bash
nix flake init -t github:hasundue/dotnix
```

The default template includes:
- Multi-platform Nix flake setup
- Treefmt for automatic code formatting
- Git pre-commit hooks
- Development shell with common tools

## Architecture

### Modular Configuration

Clear separation between system (`nixos/`), user (`home/`), and host-specific (`hosts/`) configurations. Desktop configurations are optional imports.

### Flake Structure

Uses modern Nix flakes with proper input management. All inputs follow nixpkgs for consistency to reduce duplication.

**Input Isolation**: Flake inputs are handled exclusively in `flake.nix` and exposed to modules via overlays. Modules never receive `inputs` directly, keeping them pure and reusable. External packages are accessed through `pkgs.*` after being added to overlays.

### Configuration Flow

1. `flake.nix` defines inputs and system configurations
2. Host configurations import base modules and add customizations
3. NixOS modules provide system-level configuration
4. Home Manager modules configure user environment
5. Overlays provide helper functions and custom packages
