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
      nodePackages.pyright
    ];

    xdg.configFile."nvim".source = ./nvim;
  };
}
