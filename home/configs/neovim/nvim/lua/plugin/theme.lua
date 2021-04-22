local fn = vim.fn

if fn['has']('termguicolors') then
  vim.o.termguicolors = true
end

vim.o.background = 'dark'
vim.cmd('syntax on')

local loaded_onedark, _ = pcall(function() return vim.fn['onedark#GetColors']() end)
if (not loaded_onedark) then
 do return end
end
vim.cmd('colorscheme onedark')
-- enable italics
vim.g.onedark_terminal_italics = 1
