---
name: nix-build
description: >
  Build this flake's NixOS and Home Manager configurations without activating
  them. Use for build-only validation of changes to configs, the flake, or
  packages; not for activating a configuration.
disable-model-invocation: true
---

# Nix build

This skill covers build-only validation. These commands leave a result link and
do not change the running system or user profile:

```sh
nix run .#nixos-build  # NixOS + home-manager together; leaves ./result
nix run .#home-build   # Home Manager only; leaves ./result-home
```

Use `nixos-build` for changes under `configs/hosts/`, `configs/nixos/`, or the
flake itself, and `home-build` for standalone Home Manager config-file changes.
A change that touches packages needs `nixos-build` instead; the reason is in the
Home Manager section of [the Nix activation skill](../nix-activation/SKILL.md).
Neither command activates a configuration; hand activation off to the user, or
follow the activation skill if explicitly instructed to run it.

The build apps accept passthrough flags such as `--show-trace`. They pipe output
through `nom` when stdout is a TTY, and skip it when non-TTY for minimal
output. `NOM_DISABLE=1` forces raw output even in a TTY; use it only for the
commands you run yourself in a TTY. Agent bash calls are non-TTY and already
skip `nom`. Do not add it to commands you ask the user to run, so they keep
`nom`'s output.

Do not pass `--impure` (see `AGENTS.md`).
