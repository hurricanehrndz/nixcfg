local api = vim.api                   -- vim api
local execute = api.nvim_command      -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn                     -- to call Vim functions e.g. fn.bufnr()
local g = vim.g                       -- global settings

-- Disable python plugin support
g.loaded_python_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- Sensible defaults
require('settings')

local packer_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
local packer_repo = 'https://github.com/wbthomason/packer.nvim'
local packer_install_cmd =
  '!git clone ' .. ' ' .. packer_repo .. ' ' .. packer_path

-- Install packer if missing as opt plugin
if fn.empty(fn.glob(packer_path)) > 0 then
  execute(packer_install_cmd)
  execute('packadd packer.nvim')
end

-- Auto compile when there are changes in plugins.lu
vim.cmd 'autocmd BufWritePost plugins.lua PackerCompile'

-- Install plugins
require('plugins')

-- Force loading of astronauta first
vim.cmd [[runtime plugin/astronauta.vim]]

-- Key mappings
require('keymappings')

-- Auto Command Groups
require('autocmds')

-- LSP config
require('completionconf')

-- Configure plugins
require('config')
