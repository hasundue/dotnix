---
name: update-pi-packages
description: >-
  Update pi extension packages in configs/home/pi/package.json, fetch
  changelogs, and commit. Instruct the agent to run the flake app, pipe
  to the Deno changelog script, then stage and commit.
---

# Update Pi Packages

Updates all pi extension dependencies declared in `configs/home/pi/package.json`
to their latest compatible versions, fetches changelogs for changed packages,
and commits the updated lockfile.

Do this when asked to "update pi packages", "bump pi deps", or similar.

## Setup

- [Deno](https://deno.com) on `$PATH`

## Process

### 1. Run the flake app

From the repo root:

```bash
nix run .#update-pi-packages
```

This runs `npm update --package-lock-only` in `configs/home/pi/` and prints a
TSV of changed packages: each line is `name<tab>old_version<tab>new_version`.

If no packages changed, report that and stop.

### 2. Fetch changelogs

Pipe the output into the Deno script:

```bash
nix run .#update-pi-packages | deno run --allow-net --allow-read .agents/skills/update-pi-packages/script.ts
```

This fetches CHANGELOG.md from GitHub for each changed package and extracts the
sections in the version range, producing a compact markdown report.

### 3. Stage and commit

```bash
git add configs/home/pi/package-lock.json
git commit -m "<your commit message>"
```

Write the commit message following the repo convention:

```
pi: update packages

@scope/package  old → new
  - Bullet of notable changes
  - Another change
```

Derive the bullets from the changelog report. Prefer user-facing changes
(features, fixes) over internal refactors and documentation-only changes.

### 4. Present the report

Show the user the changelog report so they know what changed.
