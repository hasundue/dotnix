---
name: nix-activation
description: >
  Apply NixOS and Home Manager configurations using this repository's activation
  commands. Use when asked to test, switch, boot, or activate a configuration;
  not for build-only validation.
---

# Nix activation

Choose the command for the requested system or Home Manager activation. Build-only
commands are documented in `AGENTS.md` and do not activate a configuration.

## NixOS

These apps wrap `nixos-rebuild` and manage the system profile:

```sh
nix run .#nixos-test    # Test without making it the default
nix run .#nixos-switch  # Apply permanently
nix run .#nixos-boot    # Set the boot entry for next reboot
```

Run them as a normal user: `sudo` is requested only for activation. Prefixing
with `sudo` also works without a second prompt.

## Home Manager

`home-switch` builds and activates without sudo:

```sh
nix run .#home-switch
```

It runs `home-manager switch --flake .#<user>@<host>`, the same command the
`hms` alias uses. Flake arguments such as `--impure` and `--refresh` go straight
through to Home Manager.
