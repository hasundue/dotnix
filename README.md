# hasundue's NixOS Configuration

Personal NixOS system configuration using Nix flakes for declarative system and user environment management.

## System Configurations

- **x1carbon** - ThinkPad X1 Carbon laptop configuration
- **nixos** - NixOS-WSL setup for Windows Subsystem for Linux

## Features

- **Home Manager** - User environment and application management
- **Stylix** - System-wide theming
- **Agenix** - Encrypted secrets management
- **Custom Neovim** - Personal Neovim configuration
- **Development Shells** - Ready-to-use environments for various languages
- **Desktop Environment** - Sway compositor with Waybar and supporting tools

## Structure

- `home/` - User environment configurations (applications, desktop settings)
- `hosts/` - Host-specific system configurations
- `nixos/` - System-level NixOS modules
- `shells/` - Development environment shells (Python, Rust, Deno, etc.)
- `secrets/` - Encrypted secrets for API keys and credentials

## Usage

Build and switch to a configuration:
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

Enter a development shell:
```bash
nix develop .#<shell-name>
```

