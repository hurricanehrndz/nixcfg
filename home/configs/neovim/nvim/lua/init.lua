-- Install packer if required
require('hrndz.packer')

-- Sensible defaults - mine
require('hrndz.settings')

-- Setup colors
require('hrndz.theme')

-- Install plugins
require('hrndz.plugins')

-- Force loading of astronauta first
--vim.cmd [[runtime plugin/astronauta.vim]]

-- Key mappings
require('hrndz.keymaps')

-- Auto Command Groups
require('hrndz.autocmds')

-- LSP config
require('hrndz.lsp')
