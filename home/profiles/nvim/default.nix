{
  pkgs,
  lib,
  inputs,
  inputs',
  ...
}: let
  neovim-nightly = with inputs'.neovim-nightly.packages; neovim;
  # Function to override the source of a package
  withSrc = pkg: src: pkg.overrideAttrs (_: {inherit src;});
  yamllint = with pkgs.python3Packages;
    buildPythonApplication {
      name = "yamllint";
      src = inputs.yamllint-src;
      doCheck = false;
      propagatedBuildInputs = [setuptools pyaml pathspec];
    };
  yamlfixer = with pkgs.python3Packages;
    buildPythonApplication {
      name = "yamlfixer";
      src = inputs.yamlfixer-src;
      doCheck = false;
      propagatedBuildInputs = [setuptools yamllint];
    };
in {
  home.packages = with pkgs; [
    alejandra
    beautysh
    black
    cbfmt
    neovim-remote
    nixpkgs-fmt
    nodePackages_latest.bash-language-server
    nodePackages.markdownlint-cli
    nodePackages.prettier
    nodePackages.pyright
    poetry
    puppet-lint
    python310Packages.flake8
    shellcheck
    shfmt
    stylua
    swift
    vale
    yamlfixer
    yamllint
  ];

  programs.zsh.initExtra = ''
    if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
      export EDITOR="nvr -l"
      export VISUAL="nvr --remote-tab-silent"
      alias vi="nvr -l"
      alias vim="nvr -l"
      alias nvim="nvr -l"
      alias v="nvr -l"
    fi
    alias v="nvim"
  '';

  programs.neovim = {
    enable = true;
    vimdiffAlias = true;
    vimAlias = true;
    viAlias = true;
    package = neovim-nightly;
    extraPackages = with pkgs; [
      # used to compile tree-sitter grammar
      tree-sitter
      # lsp
      rnix-lsp
      sumneko-lua-language-server
    ];
    extraConfig = ''
      lua << EOF
      -- Sensible defaults - mine
      require("hrndz.options")

      -- Key mappings
      require("hrndz.keymaps")
      -- Autocmds
      require("hrndz.autocmds")
      EOF


    '';
    plugins = with pkgs.vimPlugins; let
      nvim-window = pkgs.vimUtils.buildVimPluginFrom2Nix {
        pname = "nvim-window";
        src = inputs.nvim-window-src;
        version = "master";
      };
      nvim-osc52 = pkgs.vimUtils.buildVimPluginFrom2Nix {
        pname = "nvim-osc52";
        src = inputs.nvim-osc52-src;
        version = "master";
      };
      mini-nvim = pkgs.vimUtils.buildVimPluginFrom2Nix {
        pname = "mini-nvim";
        src = inputs.mini-nvim-src;
        version = "master";
      };
    in [
      # Theme
      {
        plugin = tokyonight-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.tokyonight")
        '';
      }
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.indentblankline")
        '';
      }
      {
        plugin = withSrc gitsigns-nvim inputs.gitsigns-src;
        type = "lua";
        config = ''
          require("hrndz.plugins.gitsigns")
        '';
      }
      {
        plugin = withSrc nvim-colorizer-lua inputs.nvim-colorizer-src;
        type = "lua";
        config = ''
          colorizer = require("colorizer")
          colorizer.setup()
        '';
      }
      {
        plugin = nvim-web-devicons;
        type = "lua";
        config = ''
          local devicons = require("nvim-web-devicons")
          devicons.setup({ default = true })
        '';
      }
      # Fuzzy finder
      {
        plugin = withSrc telescope-nvim inputs.telescope-nvim-src;
        type = "lua";
        config = ''
          require("hrndz.plugins.telescope")
        '';
      }
      plenary-nvim
      popup-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim

      # add some syntax highlighting
      {
        plugin = (withSrc nvim-treesitter inputs.nvim-treesitter-src).withPlugins (
          plugins:
            with plugins; [
              tree-sitter-bash
              tree-sitter-javascript
              tree-sitter-lua
              tree-sitter-make
              tree-sitter-markdown
              tree-sitter-nix
              tree-sitter-python
              tree-sitter-typescript
              tree-sitter-tsx
              tree-sitter-help
            ]
        );
        type = "lua";
        config = ''
          require("hrndz.plugins.treesitter")
        '';
      }
      # functionality
      {
        plugin = toggleterm-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.toggleterm")
        '';
      }
      # comment
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.comment")
        '';
      }
      {
        plugin = nvim-window;
        type = "lua";
        config = ''
          require("hrndz.plugins.winpicker")
        '';
      }
      # which key did I just hit
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.whichkey")
        '';
      }
      # what's did I do wrong
      {
        plugin = trouble-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.trouble")
        '';
      }
      # add completion
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          require("hrndz.plugins.completion")
        '';
      }
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-path
      cmp-buffer
      cmp-cmdline
      cmp-zsh # next is required
      deol-nvim

      # snippets
      luasnip
      cmp_luasnip
      friendly-snippets
      vim-snippets

      # formatters, linters
      null-ls-nvim

      # add lsp config
      {
        plugin = withSrc nvim-lspconfig inputs.nvim-lspconfig-src;
        type = "lua";
        config = ''
          require("hrndz.lsp")
        '';
      }
      neodev-nvim

      # nice plugins
      nvim-osc52
      vim-tmux-navigator
      nvim-notify
      undotree
      {
        plugin = feline-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.statusline")
        '';
      }
      {
        plugin = mini-nvim;
        type = "lua";
        config = ''
          require("hrndz.plugins.mini")
        '';
      }
      {
        plugin = vim-better-whitespace;
        type = "lua";
        config = ''
          require("hrndz.plugins.whitespace")
        '';
      }

      # pictograms
      lspkind-nvim
    ];
  };
  xdg.configFile = {
    "nvim" = {
      recursive = true;
      source = ./config;
    };
  };
}
