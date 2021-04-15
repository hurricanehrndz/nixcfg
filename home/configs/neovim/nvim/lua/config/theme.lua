local fn = vim.fn
local api = vim.api

if fn['has']('termguicolors') then
  vim.o.termguicolors = true
end

-- enable italics
api.nvim_set_var("onedark_terminal_italics", 1)

vim.o.background = 'dark'
vim.cmd('syntax on')
vim.cmd('colorscheme onedark')
