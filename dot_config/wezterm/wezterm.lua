local wezterm = require 'wezterm'

return {
    font = wezterm.font({ family = "Iosevka Nerd Font Mono", weight = "Regular" }),
    font_size = 16,
    initial_rows = 40,
    initial_cols = 150,

    window_decorations = "RESIZE",
    hide_tab_bar_if_only_one_tab = true,
-- Catppuccin themes
-- color_scheme = "Catppuccin Mocha",
-- color_scheme = "Catppuccin Macchiato",
-- color_scheme = "Catppuccin Frappe",
-- color_scheme = "Catppuccin Latte",

-- Gruvbox themes
-- color_scheme = "GruvboxDarkHard",
-- color_scheme = "Gruvbox (Gogh)",
-- color_scheme = "Gruvbox Dark (Gogh)",
-- color_scheme = "Gruvbox dark, hard (base16)",
-- color_scheme = "Gruvbox dark, medium (base16)",
-- color_scheme = "Gruvbox dark, pale (base16)",
-- color_scheme = "Gruvbox dark, soft (base16)",
-- color_scheme = "Gruvbox light, hard (base16)",
-- color_scheme = "Gruvbox light, medium (base16)",
-- color_scheme = "Gruvbox light, soft (base16)",
-- color_scheme = "Gruvbox Material (Gogh)",
   color_scheme = "GruvboxDark",
-- color_scheme = "GruvboxDarkHard",
-- color_scheme = "GruvboxLight",

-- Monokai themes
-- color_scheme = "DimmedMonokai",
-- color_scheme = "Monokai (terminal.sexy)",
-- color_scheme = "Monokai Pro Ristretto (Gogh)",
-- color_scheme = "Monokai (dark) (terminal.sexy)",
-- color_scheme = "Monokai Remastered",

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
