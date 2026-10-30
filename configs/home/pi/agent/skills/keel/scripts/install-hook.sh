#!/bin/sh
# keel -- install a pre-push guard that keeps ISSUE.md / SPEC.md off main.
#
# Usage: install-hook.sh [--repo PATH]
#
# The guard is a broom, not a judge: it rejects pushes to main/master whose tip
# tree still contains the working notes. It says nothing about whether the work
# is done. Override with `git push --no-verify` when you mean it.

set -eu

repo="."
while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      [ $# -ge 2 ] || { echo "keel: --repo needs a path" >&2; exit 2; }
      repo="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,8p' "$0"; exit 0 ;;
    *)
      echo "keel: unknown argument: $1" >&2; exit 2 ;;
  esac
done

root=$(cd "$repo" && git rev-parse --show-toplevel 2>/dev/null) || {
  echo "keel: not a git repository: $repo" >&2
  exit 1
}
cd "$root"

hooks_dir=".githooks"
hook="$hooks_dir/pre-push"
mkdir -p "$hooks_dir"

cat > "$hook" <<'HOOK'
#!/bin/sh
# keel guard -- block pushes to main that still carry the working notes.
zero=0000000000000000000000000000000000000000
status=0

while read -r local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in
    refs/heads/main|refs/heads/master) ;;
    *) continue ;;
  esac
  [ "$local_sha" = "$zero" ] && continue   # deleting the branch

  for f in ISSUE.md SPEC.md; do
    if git cat-file -e "$local_sha:$f" 2>/dev/null; then
      echo "keel: '$f' is in the tree you are pushing to ${remote_ref#refs/heads/}." >&2
      echo "      Remove it in the final commit, or decide it belongs there." >&2
      status=1
    fi
  done
done

if [ "$status" -ne 0 ]; then
  echo "keel: push blocked. (Override: git push --no-verify)" >&2
fi
exit "$status"
HOOK

chmod +x "$hook"
echo "keel: wrote $root/$hook"

current=$(git config --get core.hooksPath || true)
if [ -z "$current" ]; then
  git config core.hooksPath "$hooks_dir"
  echo "keel: core.hooksPath -> $hooks_dir"
elif [ "$current" != "$hooks_dir" ]; then
  echo "keel: core.hooksPath is already '$current'; left untouched."
  echo "      To activate: git config core.hooksPath $hooks_dir"
  echo "      (or call $hook from your existing pre-push)"
else
  echo "keel: guard already active via core.hooksPath"
fi
