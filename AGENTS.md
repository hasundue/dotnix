dotnix — NixOS + Home Manager flake for user `hasundue`. ~45 Nix modules, custom
packages, overlays, and dev shells.

You, the coding agent reading this file, and the system you and the user are
operating on, are likely configured via Nix in this very repository. When asked
to configure something (including yourself), work on this repository.

Your Capability:

The `nixos` MCP server should be available for NixOS-related queries. Use it
instead of web search, `nixpkgs search`, or grep-ing the store.

Commit Convention:

```
scope: imperative summary
```

Always use a scope. Imperative mood, no period at the end.

Derive scope from the **leaf** of the changed config's directory path:

| Changed path                        | Scope      |
| ----------------------------------- | ---------- |
| `configs/home/opencode/default.nix` | `opencode` |
| `configs/home/niri/default.nix`     | `niri`     |
| `configs/nixos/waybar/default.nix`  | `waybar`   |

Prepend the parent directory _only_ when the same config name exists under a
different parent (e.g. both `configs/home/waybar` and `configs/nixos/waybar`
exist → use `home/waybar` and `nixos/waybar`).

Fixed scopes (exceptions):

- `agents:` — AGENTS.md
- `flake:` — flake.nix, flake inputs

Validate:

Quick-check any config option with `nix eval` instead of a full build:

```bash
nix eval .#nixosConfigurations.<hostname>.config.<option.path>
nix eval .#homeConfigurations."<user>@<hostname>".config.<option.path>
```

Examples:

```bash
# NixOS: SSH config
nix eval .#nixosConfigurations.x1carbon.config.services.openssh

# Home Manager: window manager
nix eval .#homeConfigurations."hasundue@x1carbon".config.wayland.windowManager.niri
```

Use the right hostname (`x1carbon` or `nixos`) depending on what you're
validating. The output is the config value in Nix notation.

Build:

```bash
# NixOS + home-manager together (wraps nixos-rebuild; leaves ./result)
nix run .#nixos-build

# Home Manager only (standalone generation; leaves ./result-home)
nix run .#home-build
```

Build apps accept passthrough flags (`--impure`, `--show-trace`, etc.). They
also auto-detect TTY: if non-TTY they skip `nom` for minimal output. Force raw
even in TTY:

```bash
NOM_DISABLE=1 nix run .#nixos-build
```

Apply (NixOS; wraps nixos-rebuild, prompts for the sudo password itself):

```bash
nix run .#nixos-test    # Test without making it the default
nix run .#nixos-switch  # Apply permanently
nix run .#nixos-boot    # Set the boot entry for next reboot
```

Apply (Home Manager only):

```bash
nix run .#home-switch
```

Requires a prior build (checks for `result-home` symlink and fails with a clear
message if missing).
