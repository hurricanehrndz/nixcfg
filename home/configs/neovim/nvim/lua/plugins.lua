return require('packer').startup(function(use)

    -- Packer can manage itself as an optional plugin
    use {'wbthomason/packer.nvim', opt = true}

    --> Look and feel <--
    -- Embrace the darkside
    use 'joshdick/onedark.vim'
    -- Use the guides
    use 'lukas-reineke/indent-blankline.nvim'
    -- But mind the (git) warning signs
    use { 'lewis6991/gitsigns.nvim',
      config = function() require('gitsigns').setup({
        signs = {
          add          = {hl = 'GitGutterAdd'   , text = '+'},
          change       = {hl = 'GitGutterChange', text = '~'},
          delete       = {hl = 'GitGutterDelete', text = '_'},
          topdelete    = {hl = 'GitGutterDelete', text = '‾'},
          changedelete = {hl = 'GitGutterChange', text = '~'},
        }
      }) end
    }
    -- A splash of color in your life
    use 'norcalli/nvim-colorizer.lua'
    -- Everyone needs an icon
    use { 'kyazdani42/nvim-web-devicons',
      config = function() require'nvim-web-devicons'.setup({
        default = true;
      }) end
    }
    -- Files grow on trees?
    use 'kyazdani42/nvim-tree.lua'
    -- Use the telescope to search between the fuzz
    use {'nvim-telescope/telescope.nvim',
      requires = {
        {'nvim-lua/popup.nvim'},
        {'nvim-lua/plenary.nvim'},
        {'nvim-telescope/telescope-fzy-native.nvim'},
      },
    }
    use 'christoomey/vim-tmux-navigator'
    -- Let me see the status of the galaxy
    use {
        'glepnir/galaxyline.nvim',
        branch = 'main',
        config = function() require'statusline' end,
    }

    -- Please complete me
    use 'neovim/nvim-lspconfig'
    use 'hrsh7th/nvim-compe'
    use 'glepnir/lspsaga.nvim'    -- performance UI - code actions, diags
    use { 'onsails/lspkind-nvim', -- pictogram for completion menu
      config = function() require'lspkind'.init() end
    }
    use 'sbdchd/neoformat'
    -- snippets from LSP
    use 'norcalli/snippets.nvim'

    --> Polyglot Plugins <--
    use { 'prettier/vim-prettier', run = 'yarn install' }
    -- Better syntax
    use { 'nvim-treesitter/nvim-treesitter',
      requires = {
        -- color all the braces
        {'p00f/nvim-ts-rainbow'},
      },
      run = ':TSUpdate',
      config = function() require'nvim-treesitter.configs'.setup({
        ensure_installed = "maintained",
        highlight = {
          enable = true,
        },
        rainbow = {
          enable = true,
        },
      }) end,
    }
    use 'sheerun/vim-polyglot'
    -- Lua development -- lsp plugin
    use 'tjdevries/nlua.nvim'

    -- All hail to the Pope (tpope) + Other tools <--
    -- For the Git
    use 'tpope/vim-fugitive'
    -- Do not forget the Hub
    use 'tpope/vim-rhubarb'
    -- Need to swap some braces? This is the dentist!
    use 'tpope/vim-surround'
    -- Embrace the peanut gallery
    use 'tpope/vim-commentary'
    -- So good, why not do it again
    use 'tpope/vim-repeat'
    -- Find your coding buddy and get impaired {}
    use 'tpope/vim-unimpaired'
    -- In case you need to break-up and reconcile
    use 'AndrewRadev/splitjoin.vim'
    -- I am a Super
    use 'lambdalisue/suda.vim'
    -- Need a table?
    use 'godlygeek/tabular'
    use 'ntpeters/vim-better-whitespace'
end)
