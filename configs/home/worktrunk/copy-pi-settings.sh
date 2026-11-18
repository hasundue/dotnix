#!/usr/bin/env bash
# copy-pi-settings — give a new worktree the primary checkout's .pi/settings.json.
#
# Usage: copy-pi-settings <source-settings-file> <target-settings-file>
#
# A worktree starts from a commit, so a file git ignores is missing there:
# without .pi/settings.json pi loses the project's packages (pi-worktrunk, for
# one). The file works in every repository, so this asks no repository to opt
# in. It runs only when the source exists and the target does not, so a
# checkout that deliberately dropped or changed its own copy keeps it.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: copy-pi-settings <source-settings-file> <target-settings-file>" >&2
  exit 2
fi
source=$1
target=$2

if [ -f "$source" ] && [ ! -e "$target" ]; then
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
fi
