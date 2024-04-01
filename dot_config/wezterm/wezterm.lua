local wezterm = require 'wezterm'

-- -- config.color_scheme = 'catppuccin-macchiato'
-- -- config.color_scheme = 'Catppuccin Mocha'
-- -- config.color_scheme = 'Monokai (terminal.sexy)'
-- -- config.color_scheme = 'Monokai Pro Ristretto (Gogh)'
-- -- config.color_scheme = 'Monokai (dark) (terminal.sexy)'
-- -- config.color_scheme = 'Monokai Remastered'

return {
    font = wezterm.font({ family = "Iosevka Nerd Font Mono", weight = "Regular" }),
    font_size = 16,
    initial_rows = 40,
    initial_cols = 150,
    color_scheme = "DimmedMonokai",
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
