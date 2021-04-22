-- Install packer if required
require('hrndz.packer')

-- Install plugins
require('hrndz.plugins')

-- Sensible defaults - mine
require('hrndz.settings')

-- Force loading of astronauta first
--vim.cmd [[runtime plugin/astronauta.vim]]

-- Key mappings
require('hrndz.keymaps')

-- Auto Command Groups
require('hrndz.autocmds')

-- LSP config
require('hrndz.lsp')
