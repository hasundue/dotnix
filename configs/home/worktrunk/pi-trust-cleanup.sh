#!/usr/bin/env bash
# pi-trust-cleanup — remove the Pi project-trust entry for a removed worktree.
#
# Usage: pi-trust-cleanup <removed-worktree-path> [trust-file]
#
# The trust store is ~/.pi/agent/trust.json unless PI_TRUST_FILE is set. Pi
# guards it with a proper-lockfile lock: a directory at "<trust.json>.lock",
# taken atomically with mkdir and released with rmdir. The same protocol runs
# here, so this helper never writes while Pi holds the lock, and Pi never
# writes while this helper holds it.
#
# Failures never overwrite the store: when the lock cannot be taken or the
# JSON is invalid, the helper reports on stderr and exits non-zero with the
# file untouched. A missing key or store is not a failure: the entry may
# already be gone, so the helper exits 0 without writing.

set -euo pipefail

usage() {
  echo "usage: pi-trust-cleanup <removed-worktree-path> [trust-file]" >&2
  exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage
removed=$1
trust_file=${2:-${PI_TRUST_FILE:-$HOME/.pi/agent/trust.json}}

# Canonicalize both paths the way Pi saves keys: lexical resolution with
# symlinked ancestors followed. The worktree is already gone, so its own path
# resolves lexically; realpath -m handles both in one call.
removed=$(realpath -m -- "$removed")
trust_file=$(realpath -m -- "$trust_file")

lock_dir=$trust_file.lock
tmp=
cleanup() {
  if [ -n "$tmp" ]; then
    rm -f -- "$tmp"
  fi
  # Ignore ENOENT and never remove a lock this run did not create.
  rmdir -- "$lock_dir" 2>/dev/null || true
}

locked=
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if mkdir -- "$lock_dir" 2>/dev/null; then
    locked=1
    break
  fi
  sleep 0.02
done
if [ -z "$locked" ]; then
  echo "pi-trust-cleanup: could not lock $trust_file; leaving it unchanged" >&2
  exit 1
fi
trap cleanup EXIT

if [ ! -f "$trust_file" ]; then
  # No store: there is nothing this worktree could have written to it.
  exit 0
fi

# Fail closed on a store Pi could not read either: not an object, or values
# outside the true / false / null decisions Pi persists.
if ! jq -e 'type == "object" and (to_entries | all(.[]; .value == true or .value == false or .value == null))' \
  "$trust_file" >/dev/null; then
  echo "pi-trust-cleanup: $trust_file is not a valid Pi trust store; leaving it unchanged" >&2
  exit 1
fi

present=$(jq -r 'has($p)' --arg p "$removed" "$trust_file")
if [ "$present" != true ]; then
  # No matching key; nothing to write.
  exit 0
fi

tmp=$(mktemp "${trust_file}.clean.XXXXXX")
jq -S 'del(.[$p])' --arg p "$removed" "$trust_file" >"$tmp"
mv -f -- "$tmp" "$trust_file"
tmp=
