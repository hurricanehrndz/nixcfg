{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.neovim;
  workingGrammars = attrsets.filterAttrs (n: v:
    !builtins.elem n [
      "tree-sitter-verilog"
      "tree-sitter-fennel"
      "tree-sitter-agda"
      "tree-sitter-svelte"
      "tree-sitter-elixir"
      "tree-sitter-swift"
      "tree-sitter-gdscript"
      "tree-sitter-ocamllex"
    ]) pkgs.nvim-ts-grammars.builtGrammars;
in {
  options.hurricane.configs.neovim.enable = mkEnableOption "neovim config";

  config = mkIf cfg.enable {
    home.sessionVariables = { EDITOR = "nvim"; };
    home.packages = with pkgs; [ neovim-remote ];
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      withRuby = false;
      withNodeJs = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraConfig = ''
        lua require('init')
      '';

      extraPackages = with pkgs; [
        nodePackages.neovim
        # typescript is needed because it provides the tsserver command.
        # First, it will try to find a tsserver installed with npm install,
        # if not found, it will look in our $PATH
        # See https://github.com/theia-ide/typescript-language-server/blob/a92027377b7ba8b1c9318baad98045e5128baa8e/server/src/lsp-server.ts#L75-L94
        # See https://github.com/jlesquembre/dotfiles/blob/23d7906e5de3dbf4e9433dffeb23c95d3d9a9d06/home-manager/neovim.nix#L169

        # Language Servers
        rust-analyzer
        rnix-lsp
        terraform-ls

        nodePackages.bash-language-server
        nodePackages.dockerfile-language-server-nodejs
        nodePackages.pyright
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.vim-language-server
        nodePackages.yaml-language-server

        efm-langserver

        # Linters
        shellcheck

        # Formatters
        nodePackages.prettier
        nixfmt
        rustfmt
        shfmt
        terraform
      ];
    };

    xdg.configFile = {
      "nvim" = {
        recursive = true;
        source = ./nvim;
      };
    }  // lib.attrsets.mapAttrs' (name: drv:
      lib.attrsets.nameValuePair ("nvim/parser/"
        + (lib.strings.removePrefix "tree-sitter-" name)
        + ".so") { source = "${drv}/parser.so"; }) workingGrammars;
  };
}
