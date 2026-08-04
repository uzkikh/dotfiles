#!/bin/bash

# Get current input source using macOS API
INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null)

# Alternative method if the first one fails
if [ -z "$INPUT_SOURCE" ]; then
  # Try getting the current input source ID
  INPUT_SOURCE=$(osascript -l JavaScript -e "Application('System Events').keyboardLayouts()[0].name()" 2>/dev/null)
fi

# Map input source IDs to short codes
case "$INPUT_SOURCE" in
  *"ABC"*|*"U.S."*|*"English"*|*"com.apple.keylayout.ABC"*|*"com.apple.keylayout.US"*)
    LABEL="EN"
    ;;
  *"Russian"*|*"RussianWin"*|*"com.apple.keylayout.Russian"*|*"com.apple.keylayout.RussianWin"*)
    LABEL="RU"
    ;;
  *"Ukrainian"*|*"com.apple.keylayout.Ukrainian"*)
    LABEL="UA"
    ;;
  *)
    # Extract short name from input source
    LABEL=$(echo "$INPUT_SOURCE" | sed 's/.*keylayout\.\(.*\)/\1/' | cut -c1-2 | tr '[:lower:]' '[:upper:]')
    # If still empty, show ??
    if [ -z "$LABEL" ]; then
      LABEL="??"
    fi
    ;;
esac

# Update the item
sketchybar --set "$NAME" label="$LABEL"
