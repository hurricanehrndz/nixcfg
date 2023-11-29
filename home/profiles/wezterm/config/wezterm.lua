local wezterm = require("wezterm")
local act = wezterm.action

-- Different from default keybings
local myKeys = {
  -- tabs
  { key = "T", mods = "SUPER", action = act.SpawnTab("DefaultDomain") },
  { key = "T", mods = "SUPER|SHIFT", action = act.DisableDefaultAssignment },
  { key = "w", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
}
-- Disabled keys
for i = 1, 9 do
  -- CTRL+SHIFT + number to activate that tab
  table.insert(myKeys, {
    key = tostring(i),
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DisableDefaultAssignment,
  })
end


return {
  -- bell
  audible_bell = "Disabled",
  -- font settings
  font = wezterm.font("FiraCode Nerd Font"),
  font_size = 12.0,
  adjust_window_size_when_changing_font_size = false,

  -- color settings
  color_scheme = 'Catppuccin Latte',

  -- cursor config, invert color
  force_reverse_video_cursor = true,
  default_cursor_style = "SteadyBlock",

  -- tabbar
  enable_tab_bar = true,
  tab_bar_at_bottom = false,
  use_fancy_tab_bar = false,
  -- keybinds
  use_dead_keys = false,
  keys = myKeys,
  -- window padding
  window_padding = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0,
  },
  -- start up
  default_gui_startup_args = { "start", "--", "/run/current-system/sw/bin/zsh", "--login" },
  -- other
  exit_behavior = "Close",
}

