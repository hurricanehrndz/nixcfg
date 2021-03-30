{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.neovim;
  # workingGrammars = attrsets.filterAttrs
  #   (n: v: !builtins.elem n [
  #       "tree-sitter-verilog"
  #       "tree-sitter-yaml"
  #       "tree-sitter-fennel"
  #       "tree-sitter-nix"
  #       "tree-sitter-lua"
  #     ])
  #   pkgs.tree-sitter.builtGrammars;
in
{
  options.hurricane.configs.neovim.enable = mkEnableOption "neovim config";

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      withNodeJs = true;
      extraConfig = ''
        lua require'init'
      '';

      extraPackages = with pkgs; [
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

        # tree-sitter requirements
        gcc
        gccStdenv

        # Formatters
        nodePackages.prettier
        nixfmt
        rustfmt
        terraform
      ];
    };

    xdg.configFile = {
      "nvim" = {
        recursive = true;
        source = ./nvim;
      };
    };
    # Add all tree-sitter parsers -- out of date
    # home.file = lib.attrsets.mapAttrs'
    #   (name: drv: lib.attrsets.nameValuePair
    #     ("${config.xdg.configHome}/nvim/parser/" + (lib.strings.removePrefix "tree-sitter-" name) + ".so")
    #     { source = "${drv}/parser"; })
    #   workingGrammars;
  };
}
