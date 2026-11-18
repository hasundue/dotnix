#!/usr/bin/env bash
# rehome-live — repoint dotnix.live.* links away from a worktree being removed.
#
# Usage: rehome-live <removed-worktree-path> <primary-worktree-path>
#
# A live tree can point into a worktree (`nix run .#home-live`), and removing
# that worktree would leave `~/dotnix.live.*` dangling until the next
# activation. Relinking is enough: a live target is a path inside a checkout,
# and every checkout carries the same path. The link is left alone, with a
# warning, when the primary checkout lacks that path, so a merge is never
# blocked by it.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: rehome-live <removed-worktree-path> <primary-worktree-path>" >&2
  exit 2
fi
worktree=$1
primary=$2

for link in "$HOME"/dotnix.live.*; do
  [ -L "$link" ] || continue
  target="$(readlink "$link")"
  case "$target" in
    "$worktree" | "$worktree"/*) ;;
    *) continue ;;
  esac
  relative="${target#"$worktree"}"
  relative="${relative#/}"
  if [ ! -d "$primary/$relative" ]; then
    echo "warning: $link points into this worktree, but $primary/$relative is missing; leaving it for the next activation." >&2
    continue
  fi
  ln --force --no-target-directory --symbolic "$primary/$relative" "$link"
  echo "$(basename "$link") -> $primary/$relative (rehomed from the worktree being removed)"
done
