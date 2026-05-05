# NixOS MCP Tools Usage Guide

Two tools: `nixos_nix` (unified query) and `nixos_nix_versions` (version
history).

## Mental Model

| param     | What it selects                                                                                                                                                 |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `action`  | **What** to do: `search`, `info`, `browse`, `stats`, `channels`, `flake-inputs`, `cache`, `store`                                                               |
| `source`  | **Where** to look: `nixos`, `home-manager`, `darwin`, `flakes`, `flakehub`, `nixvim`, `wiki`, `nix-dev`, `noogle`, `nixhub`                                     |
| `type`    | **Sub-category** within the source: `packages`/`options`/`programs`/`flakes` for `source=nixos`; `list`/`ls`/`read` for `flake-inputs`; `ls`/`read` for `store` |
| `query`   | **What exactly**: search term, exact name, prefix path, store path, or flake input reference                                                                    |
| `channel` | **Which channel**: `unstable` (default), `stable`, or `25.05`                                                                                                   |
| `limit`   | Max results: 1-100 (default 20), up to 2000 for `flake-inputs read` / `store read`                                                                              |

Omit parameters you don't need; don't pass empty strings.

## Intent → Call Patterns

### Packages

| Intent                              | Call                                                  |
| ----------------------------------- | ----------------------------------------------------- |
| "Is package X in channel Y?"        | `action=info`, `query=X`, `channel=Y`                 |
| "Search for package X"              | `action=search`, `query=X`                            |
| "What programs does pkg X provide?" | `action=search`, `query=X`, `type=programs`           |
| "Which commit shipped firefox 150?" | `nix_versions` tool, `package=firefox`, `version=150` |
| "When was node 18 added?"           | `nix_versions` tool, `package=node`, `version=18`     |
| "Does X have a binary cache?"       | `action=cache`, `query=X`                             |
| "Check cache for specific version"  | `action=cache`, `query=X`, `version=1.2.3`            |
| "Check cache for a system"          | `action=cache`, `query=X`, `system=x86_64-linux`      |

### Options (NixOS / HM / Darwin / Nixvim)

| Intent                             | Call                                              |
| ---------------------------------- | ------------------------------------------------- |
| "Search NixOS options for X"       | `action=search`, `query=X`, `type=options`        |
| "Get option details for X"         | `action=info`, `query=X`, `type=option`           |
| "Home-manager option for X"        | `action=search`, `query=X`, `source=home-manager` |
| "Darwin option for X"              | `action=search`, `query=X`, `source=darwin`       |
| "Nixvim option for X"              | `action=search`, `query=X`, `source=nixvim`       |
| "Browse HM options under prefix P" | `action=browse`, `query=P`, `source=home-manager` |
| "Browse darwin options under P"    | `action=browse`, `query=P`, `source=darwin`       |

### Flakes & FlakeHub

| Intent                    | Call                                        |
| ------------------------- | ------------------------------------------- |
| "Search flakes for X"     | `action=search`, `source=flakes`, `query=X` |
| "Get FlakeHub info for X" | `action=info`, `source=flakehub`, `query=X` |

### Docs (Wiki / nix.dev / Noogle)

| Intent                    | Call                                                            |
| ------------------------- | --------------------------------------------------------------- |
| "Search NixOS wiki for X" | `action=search`, `source=wiki`, `query=X`                       |
| "Read a wiki article"     | `action=info`, `source=wiki`, `query=<title>`                   |
| "Search nix.dev docs"     | `action=search`, `source=nix-dev`, `query=X`                    |
| "Read a nix.dev page"     | `action=info`, `source=nix-dev`, `query=tutorials/nix-language` |
| "Find Nix function docs"  | `action=info`, `source=noogle`, `query=<function>`              |
| "Browse Noogle by prefix" | `action=browse`, `source=noogle`, `query=<prefix>`              |

### Store & Flake Inputs

| Intent                         | Call                                                                 |
| ------------------------------ | -------------------------------------------------------------------- |
| "List inputs of current flake" | `action=flake-inputs` (or `type=list`)                               |
| "List contents of input X"     | `action=flake-inputs`, `type=ls`, `query=X`                          |
| "Read a file in input X"       | `action=flake-inputs`, `type=read`, `query=<input>:<path>`           |
| "Read /nix/store/... file"     | `action=store`, `type=read`, `query=/nix/store/<hash>-<name>/<path>` |
| "List /nix/store/... dir"      | `action=store`, `type=ls`, `query=/nix/store/<hash>-<name>/<path>`   |

### Meta

| Intent                              | Call                                                                                    |
| ----------------------------------- | --------------------------------------------------------------------------------------- |
| "Which channels are available?"     | `action=channels`                                                                       |
| "Which commit did channel X index?" | `action=channels` (indexed commit shown when known)                                     |
| "Count packages/options"            | `action=stats` (supports nixos, home-manager, darwin, flakes, flakehub, nixvim, noogle) |

## Workflows

### Full package triage

```
1. nixos_nix(action=info, query=<pkg>, channel=unstable)
   → confirms existence, attribute path, version, platforms
2. nixos_nix(action=info, query=<pkg>, channel=stable)
   → compare version availability
3. nixos_nix(action=cache, query=<pkg>)
   → check binary cache
4. nixos_nix_versions(package=<pkg>, limit=5)
   → version history across nixpkgs commits
```

### Flake input exploration

```
1. nixos_nix(action=flake-inputs, type=list)
   → list all inputs of current flake
2. nixos_nix(action=flake-inputs, type=ls, query=<input>)
   → browse inside a specific input
3. nixos_nix(action=flake-inputs, type=read, query=<input>:<path>)
   → read a file from an input
```

## Common Pitfalls

- **`action=browse` only works with `source=home-manager`, `darwin`, `nixvim`,
  or `noogle`** — not NixOS. For NixOS options, use
  `action=search, type=options` or `action=info, type=option`.
- **`action=info` is not supported for `source=flakes`** — use `action=search`
  instead.
- **`action=info` for `source=nixos`** matches exact attribute path first, then
  exact pname. If multiple packages share a pname (e.g. firefox / firefox-esr),
  the canonical attribute wins and the response flags it.
- **`type` meaning changes by context**: for `source=nixos` with
  `action=search`, valid types are `packages`/`options`/`programs`/`flakes`;
  with `action=info`, valid types are `package`/`option`.
- **`source` doubles as flake directory** for `action=flake-inputs`: pass a path
  instead of a source name to inspect a different flake's inputs. Omit or set to
  `"."` for the current project.
- **`limit` defaults to 20** but for `flake-inputs read` and `store read`, if
  left at 20 it's promoted to `DEFAULT_LINE_LIMIT` (typically 200). Max is 2000
  for these two actions.
- **stats** are not available for `wiki`, `nix-dev`, or `nixhub`.
