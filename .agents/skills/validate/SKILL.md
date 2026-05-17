---
name: validate
description: >-
  How to validate, build, and apply Home Manager changes in this repo.
---

# Validate

## Fast Validation

Quick-check any config option with `nix eval` instead of a full build:

```bash
nix eval .#nixosConfigurations.<hostname>.config.<option.path>
nix eval .#homeConfigurations."<user>@<hostname>".config.<option.path>
```

### Examples

```bash
# NixOS: SSH config
nix eval .#nixosConfigurations.x1carbon.config.services.openssh

# Home Manager: window manager
nix eval .#homeConfigurations."hasundue@x1carbon".config.wayland.windowManager.niri
```

Use the right hostname (`x1carbon` or `nixos`) depending on what you're
validating. The output is the config value in Nix notation.

## Build

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

## Apply (Home Manager only)

```bash
nix run .#home-switch
```

Requires a prior build (checks for `result-home` symlink and fails with a clear
message if missing).
