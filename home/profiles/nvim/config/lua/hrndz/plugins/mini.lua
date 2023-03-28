---@diagnostic disable-next-line: missing-parameter
local has_mini, misc = pcall(require, "mini.misc")
if not has_mini then
  return
end

misc.setup({})
require("mini.ai").setup({})               -- extended creations of a/i text objects
require("mini.align").setup({})            -- align text
require("mini.surround").setup({})         -- surround text
