#!/bin/bash
# macOS defaults, all disabled by default. Uncomment a line to enable it.
#
# This is run_onchange_, and its state is keyed on the content of this file, so
# uncommenting a line changes the hash and the setting applies on the next
# `chezmoi apply` by itself. No `chezmoi state delete-bucket` needed.
#
# Every `defaults write` keeps its `killall` attached, and both must be
# uncommented together: cfprefsd caches preferences and can write the old value
# back over ours while the owning app is running. Newer macOS also routes some
# domains into an app's sandbox container rather than ~/Library/Preferences,
# which is another reason to let the app reload rather than poke the file.
#
# Note that the killalls below restart Dock, SystemUIServer and Finder --
# windows are not lost, but the UI visibly blinks.

set -uo pipefail

# Put the Dock on the left of the screen
defaults write com.apple.dock "orientation" -string "left" && killall Dock

# Autohide the Dock when the mouse is out
defaults write com.apple.dock "autohide" -bool "true" && killall Dock

# Set dock icon size of 40 pixels
defaults write com.apple.dock "tilesize" -int "40" && killall Dock

# Hide all icons on desktop
defaults write com.apple.finder "CreateDesktop" -bool "false" && killall Finder

# Screenshot location.
# defaults write com.apple.screencapture location ~/Desktop/Screenshots
# killall SystemUIServer

# System Settings -> Desktop & Dock -> Group windows by application.
# defaults write com.apple.dock expose-group-apps -bool true
# killall Dock

# System Settings -> Desktop & Dock -> Displays have separate Spaces.
# defaults write com.apple.spaces spans-displays -bool false
# killall SystemUIServer

# Disable the accent-character menu, so holding a key repeats it instead.
# Applies per app on next launch, no killall needed.
# defaults write -g ApplePressAndHoldEnabled -bool true

# Hide all desktop icons.
# defaults write com.apple.finder CreateDesktop -bool false
# killall Finder

# The FZF_DEFAULT_OPTS block that used to live in setup.sh is gone on purpose:
# it used fish's universal-export flag, which bash rejects at runtime with
# `set: -U: invalid option`, and the variable is already exported from
# config.fish.tmpl anyway.

exit 0
