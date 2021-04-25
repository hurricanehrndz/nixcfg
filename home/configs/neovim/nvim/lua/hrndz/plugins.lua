return require('packer').startup(function(use)

  -- Packer can manage itself
  use {'wbthomason/packer.nvim'}
  -- let's go to space
  use 'tjdevries/astronauta.nvim'

  -- > Look and feel <--
  -- Embrace the darkside
  use 'joshdick/onedark.vim'
  -- Use the guides
  use {'lukas-reineke/indent-blankline.nvim', branch = "lua"}
  -- Show me end of column
  use 'tjdevries/overlength.vim'
  -- But mind the (git) warning signs
  use({'lewis6991/gitsigns.nvim',})

  -- A splash of color in your life
  use 'norcalli/nvim-colorizer.lua'
  -- Everyone needs an icon
  use {'kyazdani42/nvim-web-devicons', config = function() require'nvim-web-devicons'.setup({default = true}) end}
  -- Files grow on trees?
  use 'kyazdani42/nvim-tree.lua'
  -- Use the telescope to search between the fuzz
  use {
    'nvim-telescope/telescope.nvim',
    requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}, {'nvim-telescope/telescope-fzy-native.nvim'}}
  }
  use 'christoomey/vim-tmux-navigator'
  -- Let me see the status of the galaxy
  use {
    -- effects start page (redraw)
    'glepnir/galaxyline.nvim',
    branch = 'main'
  }

  -- Please complete me
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-compe'
  use 'glepnir/lspsaga.nvim' -- performance UI - code actions, diags
  use {
    'onsails/lspkind-nvim', -- pictogram for completion menu
    config = function() require'lspkind'.init() end
  }
  use 'sbdchd/neoformat'
  -- Snippets
  use 'rafamadriz/friendly-snippets'
  use 'hrsh7th/vim-vsnip'
  -- use 'norcalli/snippets.nvim'

  -- > Polyglot Plugins <--
  --  Better syntax
  use({
    'nvim-treesitter/nvim-treesitter',
    requires = {
      -- color all the braces
      {'p00f/nvim-ts-rainbow'}
    },
    -- Parsers are maintained by nix
    config = function()
      require'nvim-treesitter.configs'.setup({
        ensure_installed = "maintained",
        highlight = {enable = true, disable = {"nix"}},
        rainbow = {enable = true, disable = {'bash', 'nix'}}
      })
    end
  })
  use 'sheerun/vim-polyglot' -- forces redraw effecting startpage
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
  -- In case you need to break-up and reconcile
  use 'AndrewRadev/splitjoin.vim'
  -- I am a Super
  use 'lambdalisue/suda.vim'
  -- Need a table?
  use 'godlygeek/tabular'
  use 'ntpeters/vim-better-whitespace'
end)
