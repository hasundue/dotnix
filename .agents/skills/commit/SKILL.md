---
name: commit
description: >-
  You MUST read this before `git commit`. Covers message format, scope
  derivation, and conventions for commit messages in this repo.
---

# Commit

Read this _before_ composing any commit message.

## Format

```
scope: imperative summary
```

Always use a scope. Imperative mood, no period at the end.

## Scope Derivation

Derive scope from the **leaf** of the changed config's directory path:

| Changed path                       | Scope    |
| ---------------------------------- | -------- |
| `configs/home/pi/default.nix`      | `pi`     |
| `configs/home/niri/default.nix`    | `niri`   |
| `configs/nixos/waybar/default.nix` | `waybar` |

Prepend the parent directory _only_ when the same config name exists under a
different parent (e.g. both `configs/home/waybar` and `configs/nixos/waybar`
exist → use `home/waybar` and `nixos/waybar`).

## Fixed Scopes (Exceptions)

These don't map to a config directory but are used for their named paths:

- `agents:` — AGENTS.md, .agents/ directory
- `flake:` — flake.nix, flake inputs
