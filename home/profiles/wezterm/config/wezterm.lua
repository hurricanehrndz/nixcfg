local wezterm = require("wezterm")
local act = wezterm.action

-- simple keybings
local myKeys = {
  -- window control
  { key = 'm', mods = 'SUPER', action = wezterm.action.Hide },
  -- font sizing
  { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
  { key = "=", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "0", mods = "SUPER", action = act.ResetFontSize },
  -- copy & paste
  { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  -- tabs
  { key = "T", mods = "SUPER|SHIFT", action = act.SpawnTab("DefaultDomain") },
  { key = "{", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "}", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },
  { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },
  { key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = true }) },

}

for i = 1, 8 do
  -- SUPER + number to activate that tab
  table.insert(myKeys, {
    key = tostring(i),
    mods = 'SUPER',
    action = act.ActivateTab(i - 1),
  })
end

-- TokyoNight color_scheme
local my_colorschemes = {
  ["TokyoNight-Night"] = {
    foreground = "#c0caf5",
    background = "#1a1b26",

    -- Normal colors
    ansi = { "#15161E", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6" },
    -- Bright colors
    brights = { "#414868", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5" },
    indexed = {
      [16] = "#ff9e64",
      [17] = "#db4b4b",
    },
  },
}

return {
  -- bell
  audible_bell = "Disabled",
  -- font settings
  font = wezterm.font("SauceCodePro Nerd Font"),
  font_size = 14.0,
  adjust_window_size_when_changing_font_size = false,

  -- color settings
  color_scheme = "TokyoNight-Night",
  color_schemes = my_colorschemes,

  -- cursor config, invert color
  force_reverse_video_cursor = true,
  default_cursor_style = "SteadyBlock",

  -- tabbar
  enable_tab_bar = true,
  tab_bar_at_bottom = false,
  use_fancy_tab_bar = false,
  -- keybinds
  use_dead_keys = false,
  disable_default_key_bindings = true,
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

