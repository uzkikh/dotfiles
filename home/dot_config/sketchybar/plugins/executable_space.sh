#!/bin/sh

# NOT USED - This script is for native macOS Mission Control spaces
# We use AeroSpace window manager instead (see aerospace_switch.sh)

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

sketchybar --set "$NAME" background.drawing="$SELECTED"
