local api = vim.api                   -- vim api
local execute = api.nvim_command      -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn                     -- to call Vim functions e.g. fn.bufnr()
local g = vim.g                       -- a table to access global variables


local packer_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'
local packer_repo = 'https://github.com/wbthomason/packer.nvim'
local packer_install_cmd =
    '!git clone ' .. ' ' .. packer_repo .. ' ' .. packer_path

-- install packer if missing
if fn.empty(fn.glob(packer_path)) > 0 then
  execute(packer_install_cmd)
end
