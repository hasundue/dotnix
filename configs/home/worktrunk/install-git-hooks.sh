#!/usr/bin/env bash
# install-git-hooks — link a worktree's pre-commit config without a dev shell.
#
# Usage: install-git-hooks
#
# A new worktree has no .pre-commit-config.yaml because git ignores it. The
# dev shell's hook creates the symlink, but entering the dev shell also builds
# every package it contains. This links just the config instead. Repositories
# without a `pre-commit-config` package need no setup, so this no-ops there.

set -euo pipefail

if [ ! -f flake.nix ]; then
  exit 0
fi

config=$(nix eval --raw .#pre-commit-config 2>/dev/null || true)
if [ -z "$config" ]; then
  exit 0
fi

nix build --no-link .#pre-commit-config
ln -sfn "$config" .pre-commit-config.yaml
