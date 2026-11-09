#!/usr/bin/env bash
# Dismiss an application's notifications when one of its windows gains focus.
#
# mako cannot do this by itself: it is a layer-shell client that never learns
# which window is focused, and mako.5 has no option for it. Apps that close
# their own notifications once they are activated (web apps in Chrome do it
# from JavaScript) therefore behave differently from apps that leave them
# sitting in the corner — and since mako's default timeout is 0, the latter
# never expire.
#
# So ask niri instead: it reports the focused window and its app-id.

set -euo pipefail

# Matching is by name, and the two sides rarely agree on one: niri reports a
# window's `app_id`, while the notification carries whatever the client passed
# as `app_name`. Names are compared after lowercasing and dropping everything
# that is not alphanumeric, so `google-chrome` already matches "Google Chrome"
# and `Slack` matches "slack".
#
# The exceptions live in focus-dismiss.nix, which writes them here as JSON and
# substitutes the path; a manual run can point MAKO_FOCUS_DISMISS_ALIASES at
# its own file.
aliases=$(cat "${MAKO_FOCUS_DISMISS_ALIASES:-@aliases@}")

declare -A app_ids=()

# "Google Chrome" and "google-chrome" both come out as "googlechrome".
normalize() {
  local name=${1,,}
  printf '%s' "${name//[^[:alnum:]]/}"
}

# Dismiss every visible notification belonging to app_id.
dismiss_for() {
  local app_id=$1
  local -a names=("$app_id")
  local id app_name name

  while IFS= read -r name; do
    names+=("$name")
  done < <(jq -r --arg id "$app_id" '.[$id] // [] | .[]' <<<"$aliases")

  # Critical notifications stay until the user deals with them.
  while IFS=$'\t' read -r id app_name; do
    [ -n "$id" ] || continue
    for name in "${names[@]}"; do
      if [ "$(normalize "$app_name")" = "$(normalize "$name")" ]; then
        makoctl dismiss --no-history -n "$id"
        break
      fi
    done
  done < <(makoctl list -j </dev/null |
    jq -r '.[] | select(.urgency != "critical")
           | [.id, (.app_name // "")] | @tsv')
}

main() {
  local line window_id app_id entry

  while IFS= read -r line; do
    case $line in
      *'"WindowsChanged"'*)
        # Full snapshot, sent once when the stream opens.
        app_ids=()
        while IFS=$'\t' read -r window_id app_id; do
          [ -n "$window_id" ] && app_ids[$window_id]=$app_id
        done < <(jq -r '.WindowsChanged.windows[]
                      | [.id, (.app_id // "")] | @tsv' <<<"$line")
        ;;
      *'"WindowOpenedOrChanged"'*)
        # Also the place where a window gets its app-id, which can be late.
        if entry=$(jq -r '.WindowOpenedOrChanged.window
                           | [.id, (.app_id // "")] | @tsv' <<<"$line") &&
          IFS=$'\t' read -r window_id app_id <<<"$entry"; then
          app_ids[$window_id]=$app_id
        fi
        ;;
      *'"WindowClosed"'*)
        window_id=$(jq -r '.WindowClosed.id // empty' <<<"$line")
        [ -n "$window_id" ] && unset "app_ids[$window_id]"
        ;;
      *'"WindowFocusChanged"'*)
        window_id=$(jq -r '.WindowFocusChanged.id // empty' <<<"$line")
        if [ -n "$window_id" ] && [ -n "${app_ids[$window_id]:-}" ]; then
          dismiss_for "${app_ids[$window_id]}"
        fi
        ;;
    esac
  done < <(niri msg --json event-stream)
}

main "$@"
