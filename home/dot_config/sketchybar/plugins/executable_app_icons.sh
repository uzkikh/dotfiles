#!/bin/bash

# Icon mapping for sketchybar-app-font
# The font uses ligatures: typing the app name shows the icon
# Format: :app_name: -> icon

get_icon_for_app() {
  local app="$1"

  # First, try auto-generating ligature from app name
  # Convert to lowercase and replace spaces with underscores
  local auto_ligature=$(echo "$app" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')

  # sketchybar-app-font uses the format :appname: as ligature
  # The font automatically converts these to icons
  # Only explicit mappings here are for apps with special naming
  case "$app" in
    # Browsers (only special cases with naming differences)
    "Safari Technology Preview") echo ":safari:" ;;
    "Firefox Nightly"|"Firefox Developer Edition") echo ":firefox:" ;;
    "Google Chrome"|"Chrome") echo ":google_chrome:" ;;
    "Brave Browser"|"Brave") echo ":brave_browser:" ;;
    "Microsoft Edge"|"Edge") echo ":microsoft_edge:" ;;

    # Terminals (only special cases)
    "Wezterm") echo ":wezterm:" ;;
    "iTerm2"|"iTerm") echo ":iterm:" ;;

    # Editors & IDEs (only special cases)
    "Visual Studio Code"|"Code"|"VSCode") echo ":visual_studio_code:" ;;
    "IntelliJ IDEA"|"IntelliJ") echo ":idea:" ;;
    "Android Studio") echo ":android_studio:" ;;
    "Neovim"|"Neovide"|"VimR"|"Vim") echo ":vim:" ;;

    # Communication (only special cases)
    "WhatsApp") echo ":whats_app:" ;;
    "Microsoft Teams"|"Teams") echo ":microsoft_teams:" ;;
    "zoom.us") echo ":zoom:" ;;

    # Productivity (only special cases)
    "Reeder") echo ":reeder5:" ;;
    "Apple Music") echo ":music:" ;;
    "Apple TV") echo ":tv:" ;;

    # Design & Graphics (only special cases)
    "Adobe Photoshop"|"Photoshop") echo ":photoshop:" ;;
    "Adobe Illustrator"|"Illustrator") echo ":illustrator:" ;;

    # Utilities (only special cases)
    "Find My") echo ":find_my:" ;;
    "System Settings"|"System Preferences") echo ":system_preferences:" ;;
    "Activity Monitor") echo ":activity_monitor:" ;;
    "Docker Desktop") echo ":docker:" ;;
    "1Password") echo ":one_password:" ;;

    # Development (only special cases)
    "GitHub Desktop") echo ":git_hub:" ;;
    "TablePlus") echo ":table_plus:" ;;
    "LM Studio") echo ":lm_studio:" ;;

    # AI (only special cases)
    "ChatGPT") echo ":openai:" ;;
    "GitHub Copilot") echo ":github_copilot:" ;;

    # Finance & Trading (only special cases)

    # Default: try auto-generated ligature from app name
    # If font doesn't support it, it will fallback to showing the text
    *)
      echo ":${auto_ligature}:"
      ;;
  esac
}
