-- Seamless Ctrl+hjkl navigation between nvim windows and Zellij panes.
-- Companion to the zellij plugin vim-zellij-navigator: it forwards Ctrl+hjkl into nvim,
-- and smart-splits, at the EDGE of an nvim window, runs `zellij action move-focus` to cross into a Zellij pane.
return {
  "mrjones2014/smart-splits.nvim",
  opts = {
    -- required: zellij is not auto-detected
    multiplexer_integration = "zellij",
    at_edge = "wrap",
  },
  keys = {
    -- override LazyVim's default <C-w>hjkl
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Window/pane left" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Window/pane down" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Window/pane up" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Window/pane right" },
  },
}
