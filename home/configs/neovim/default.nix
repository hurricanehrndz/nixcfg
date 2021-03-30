{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.neovim;
in
{
  options.hurricane.configs.neovim.enable = mkEnableOption "neovim config";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      neovim-nightly
      nodePackages.npm

      nodePackages.typescript
      nodePackages.typescript-language-server

      nodePackages.bash-language-server
      nodePackages.vim-language-server
      nodePackages.yaml-language-server
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.dockerfile-language-server-nodejs

      nodePackages.pyright

      # Language Server
      sumneko-lua-language-server
      rnix-lsp
      terraform-ls

      # Formatters
      nodePackages.prettier
      nixfmt
      rustfmt
      terraform
    ];

    xdg.configFile = {
      "nvim" = {
        recursive = true;
        source = ./nvim;
      };
    };
    # Add all tree-sitter parsers
    home.file = lib.attrsets.mapAttrs'
      (name: drv: lib.attrsets.nameValuePair
        ("${config.xdg.configHome}/nvim/parser/" + (lib.strings.removePrefix "tree-sitter-" name) + ".so")
        { source = "${drv}/parser"; })
      pkgs.tree-sitter.builtGrammars;
  };
}
