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
      rnix-lsp
      nodePackages.npm
      nodePackages.bash-language-server
      nodePackages.pyright
      nodePackages.typescript-language-server
      nodePackages.vim-language-server
      nodePackages.yaml-language-server
      sumneko-lua-language-server
    ];

    xdg.configFile."nvim" = {
      recursive = true;
      source = ./nvim;
    };
  };
}
