local api = vim.api                   -- vim api
local execute = api.nvim_command      -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn                     -- to call Vim functions e.g. fn.bufnr()

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

