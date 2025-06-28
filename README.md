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
- **Flake Templates** - Reusable project templates with development tooling

## Structure

- `home/` - User environment configurations (applications, desktop settings)
- `hosts/` - Host-specific system configurations
- `nixos/` - System-level NixOS modules
- `shells/` - Development environment shells (Python, Rust, Deno, etc.)
- `secrets/` - Encrypted secrets for API keys and credentials
- `templates/` - Flake templates for new projects

## Usage

### System Management

Build and switch to a configuration:
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

### Development

Enter a development shell:
```bash
nix develop .#<shell-name>
```

### Templates

Initialize a new project with the default template:
```bash
nix flake init -t github:hasundue/dotnix
```

The default template includes:
- Multi-platform Nix flake setup
- Treefmt for automatic code formatting
- Git pre-commit hooks
- Development shell with common tools

