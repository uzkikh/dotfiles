#!/bin/zsh

# Updates app icons for all workspaces (9 workspaces updated in single batch)
# Triggered by: front_app_switched, space_windows_change
# Note: NOT subscribed to aerospace_workspace_change to avoid duplicate calls,
#       but triggers it at the end to force SketchyBar redraw

# Source the app icons mapping
source "$CONFIG_DIR/plugins/app_icons.sh"

# Get all windows in one call
ALL_WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)

# Build associative array of workspace -> apps
typeset -A workspace_apps

if [ -n "$ALL_WINDOWS" ]; then
  while IFS='|' read -r ws app; do
    if [ -n "$ws" ] && [ -n "$app" ]; then
      # Get icon for this app
      icon=$(get_icon_for_app "$app")
      if [ -n "$icon" ]; then
        # Append icon to workspace's icon list
        if [ -n "${workspace_apps[$ws]}" ]; then
          workspace_apps[$ws]="${workspace_apps[$ws]} $icon"
        else
          workspace_apps[$ws]="$icon"
        fi
      fi
    fi
  done <<< "$ALL_WINDOWS"
fi

# Update all workspace app labels in a single batch command
updates=()

for sid in 1 2 3 4 5 6 7 8 9; do
  icons="${workspace_apps[$sid]}"

  # Adjust content based on whether workspace has apps
  if [ -n "$icons" ]; then
    # Workspace has apps - number and icons with spacing
    apps_label_padding_left=6
    apps_label_padding_right=7
    apps_width=-1
  else
    # Workspace is empty - just the number
    apps_label_padding_left=0
    apps_label_padding_right=0
    apps_width=0
  fi

  updates+=(--set "space.$sid.apps" label="$icons" width="$apps_width" label.padding_left="$apps_label_padding_left" label.padding_right="$apps_label_padding_right")
done

# Execute all updates in a single sketchybar call
sketchybar "${updates[@]}" 2>/dev/null

# Force redraw by triggering workspace change event for current workspace
CURRENT_WS=$(aerospace list-workspaces --focused 2>/dev/null)
if [ -n "$CURRENT_WS" ]; then
  sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$CURRENT_WS 2>/dev/null
fi
