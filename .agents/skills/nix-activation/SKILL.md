---
name: nix-activation
description: >
  Apply NixOS and Home Manager configurations using this repository's activation
  commands. Use when asked to test, switch, boot, or activate a configuration;
  not for build-only validation.
disable-model-invocation: true
---

# Nix activation

Choose the command for the requested system or Home Manager activation.
Build-only commands are in [the Nix build skill](../nix-build/SKILL.md). They
do not activate a configuration.

## NixOS

These apps wrap `nixos-rebuild` and manage the system profile:

```sh
nix run .#nixos-test    # Test without making it the default
nix run .#nixos-switch  # Apply permanently
nix run .#nixos-boot    # Set the boot entry for next reboot
```

The user runs them as a normal user: `sudo` is requested only for activation.
The user may also prefix a command with `sudo` without a second prompt. The
agent does not request a sudo password or supply non-interactive elevation.

## Home Manager

`home-switch` builds and activates without sudo:

```sh
nix run .#home-switch
```

It runs `home-manager switch --flake .#<user>@<host>`, the same command the
`hms` alias uses. Flake arguments such as `--refresh` go straight through to
Home Manager; do not pass `--impure` (see `AGENTS.md`). On a TTY, `home-switch`
sends Nix's `internal-json` log and errors through `nom`, while Home Manager's
and the activation script's stdout goes to
`${XDG_CACHE_HOME:-$HOME/.cache}/home-manager/switch.log` and is printed only
if the switch fails. `NOM_DISABLE=1` keeps the fully raw output; agent bash
calls are non-TTY and already skip this handling. Do not add `NOM_DISABLE=1`
to commands you ask the user to run.

The standalone configuration installs packages into the home-manager profile
rather than the per-user system profile that `useUserPackages` uses, so for a
change that touches packages rather than config files, use a `nixos-*` command
instead of `home-switch`. For build-only inspection of such a change, use
`nixos-build` from the build skill.

## Verification

After each activation, verify the resulting state as far as possible in this
environment. For checks that do not need sudo, use `home-switch` subject to the
package exception above, or a build-only command from the build skill. Do not
ask for a sudo password or add non-interactive elevation.

The `nixos-*` activation apps do not use `nom`: their output is raw because the
status ticker would erase sudo's password prompt. Output handling for the build
apps is described in the build skill.
