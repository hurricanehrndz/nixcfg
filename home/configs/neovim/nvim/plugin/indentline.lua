local loaded_indent_blankline, _ = pcall(function() return vim.g.loaded_indent_blankline end)
if (not loaded_indent_blankline) then
 do return end
end

local g = vim.g                       -- global settings
g.indent_blankline_space_char = ' '
g.indent_blankline_space_char_blankline = ' '
g.indent_blankline_char = "┊"
g.indent_blankline_filetype_exclude = { 'help', 'packer' }
g.indent_blankline_buftype_exclude = { 'terminal', 'nofile'}
g.indent_blankline_char_highlight = 'LineNr'
g.indent_blankline_show_first_indent_level = false
