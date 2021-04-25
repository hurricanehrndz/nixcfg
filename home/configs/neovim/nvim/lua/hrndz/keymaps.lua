local api = vim.api

local nmap = { noremap=true }
-- Ctrl+[hjkl] navigate cursor in insert or command mode
api.nvim_set_keymap('i',  '<C-h>',  '<Left>',   nmap)
api.nvim_set_keymap('c',  '<C-h>',  '<Left>',   nmap)
api.nvim_set_keymap('i',  '<C-j>',  '<Down>',   nmap)
api.nvim_set_keymap('c',  '<C-j>',  '<Down>',   nmap)
api.nvim_set_keymap('i',  '<C-k>',  '<Up>',     nmap)
api.nvim_set_keymap('c',  '<C-k>',  '<Up>',     nmap)
api.nvim_set_keymap('i',  '<C-l>',  '<Right>',  nmap)
api.nvim_set_keymap('c',  '<C-l>',  '<Right>',  nmap)


-- tmux navigator
vim.g.tmux_navigator_no_mappings = 1
-- Alt+[hjkl] navigate windows
api.nvim_set_keymap('n', '<A-h>', [[<cmd>TmuxNavigateLeft<CR>]], nmap)
api.nvim_set_keymap('n', '<A-j>', [[<cmd>TmuxNavigateDown<CR>]], nmap)
api.nvim_set_keymap('n', '<A-k>', [[<cmd>TmuxNavigateUp<CR>]], nmap)
api.nvim_set_keymap('n', '<A-l>', [[<cmd>TmuxNavigateRight<CR>]], nmap)
-- Alt+[hjkl] navigate windows from terminal
api.nvim_set_keymap('t', '<A-h>', [[<cmd>TmuxNavigateLeft<CR>]], nmap)
api.nvim_set_keymap('t', '<A-j>', [[<cmd>TmuxNavigateDown<CR>]], nmap)
api.nvim_set_keymap('t', '<A-k>', [[<cmd>TmuxNavigateUp<CR>]], nmap)
api.nvim_set_keymap('t', '<A-l>', [[<cmd>TmuxNavigateRight<CR>]], nmap)


-- esc from terminal
api.nvim_set_keymap('t', '<esc>', [[<C-\><C-N><esc>]], nmap)


-- save with zz
api.nvim_set_keymap('n',  'zz',         [[<cmd>update<CR>]],     nmap)
api.nvim_set_keymap('n',  '<space>zz',  [[<cmd>SudaWrite<CR>]],  nmap)


-- keybind disable hightlights
api.nvim_set_keymap('n', ',l', [[<cmd>nohlsearch<CR>]], nmap)


-- delete buffer
api.nvim_set_keymap('n',  '<space>bd',  [[<cmd>bd!<CR>]],  nmap)
