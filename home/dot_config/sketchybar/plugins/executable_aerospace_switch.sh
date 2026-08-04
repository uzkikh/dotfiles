#!/bin/zsh

# Fast script - only updates workspace highlighting (no aerospace calls)
# Triggered by aerospace_workspace_change event

# Get the focused workspace from the event
if [ -z "$FOCUSED_WORKSPACE" ]; then
  exit 0
fi

# Update all workspace brackets highlighting in a single batch
declare -a updates=()

for sid in 1 2 3 4 5 6 7 8 9; do
  if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
    drawing="on"
  else
    drawing="off"
  fi
  updates+=(--set "space_bracket.$sid" background.drawing="$drawing")
done

# Execute all updates in a single sketchybar call
sketchybar "${updates[@]}" 2>/dev/null
