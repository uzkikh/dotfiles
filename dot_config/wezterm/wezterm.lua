local wezterm = require 'wezterm'

return {
    font = wezterm.font({ family = "Iosevka Nerd Font Mono", weight = "Regular" }),
    font_size = 18,
    initial_rows = 40,
    initial_cols = 150,

    window_decorations = "RESIZE",
    hide_tab_bar_if_only_one_tab = true,
    window_close_confirmation = 'NeverPrompt',
    color_scheme = "Catppuccin Mocha",
    -- window_background_opacity = 0.9,

    keys = {
        { key = "Enter", mods = "ALT", action = "DisableDefaultAssignment" }, {
        key = "c",
        mods = "SHIFT|ALT",
        action = wezterm.action({
            SplitHorizontal = { domain = "CurrentPaneDomain" }
        })
    }, {
        key = "v",
        mods = "SHIFT|ALT",
        action = wezterm.action({
            SplitVertical = { domain = "CurrentPaneDomain" }
        })
    }, {
        key = "LeftArrow",
        mods = "ALT|SHIFT",
        action = wezterm.action({ ActivatePaneDirection = "Left" })
    }, {
        key = "RightArrow",
        mods = "ALT|SHIFT",
        action = wezterm.action({ ActivatePaneDirection = "Right" })
    }, {
        key = "UpArrow",
        mods = "ALT|SHIFT",
        action = wezterm.action({ ActivatePaneDirection = "Up" })
    }, {
        key = "DownArrow",
        mods = "ALT|SHIFT",
        action = wezterm.action({ ActivatePaneDirection = "Down" })
    }
    }
}
