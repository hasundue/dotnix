#!/usr/bin/env bash

# Function to get window count
get_window_count() {
  swaymsg -t get_tree | jq -r '
    # Find parent of focused container
    def find_parent_container:
      .. | select(.nodes? != null) | select(.nodes[] | .focused? == true);
    
    # Get parent container info
    find_parent_container |
    if .layout == "tabbed" or .layout == "stacked" then
      # Find which index the focused node is at
      (.nodes | to_entries | map(select(.value.focused == true)) | .[0].key + 1) as $focused_idx |
      (.nodes | length) as $total |
      if $total > 1 then
        "[\($focused_idx)/\($total)]"
      else
        ""
      end
    else
      ""
    end
  ' | head -1
}

# Print initial state
get_window_count

# Subscribe to Sway events and update on window, workspace, and binding changes
# Note: Layout changes are only detected via binding events (keyboard shortcuts)
swaymsg -t subscribe -m '["window","workspace","binding"]' | while read -r event; do
  get_window_count
done
