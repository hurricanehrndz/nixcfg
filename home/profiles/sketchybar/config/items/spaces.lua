local colors = require("colors")
-- local app_icons = require("app_icons")
-- local icons = require("icons")
local settings = require("settings")

-- 'workspace W' # web
-- 'workspace A' # audio
-- 'workspace R' # ramblings (chat)
-- 'workspace S' # settings
-- 'workspace T' # terminal
-- 'workspace V' # video
-- 'workspace C' # code (vs)
-- 'workspace B' # books
-- 'workspace D' # docs
-- 'workspace F' # firefox

local spaces = {}

for i = 1, 10, 1 do
  local space = sbar.add("space", "space." .. i, {
    icon = {
      font = { family = settings.font.numbers },
      string = i,
      padding_left = 15,
      padding_right = 8,
      color = colors.white,
      highlight_color = colors.red,
    },
    label = {
      padding_right = 20,
      color = colors.grey,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg1,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
    -- popup = { background = { border_width = 5, border_color = colors.black } },
  })

  spaces[i] = space
end
