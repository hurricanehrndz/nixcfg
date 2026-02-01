{
  inputs',
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
  nvim-pdenv = inputs'.pdenv.packages.pdenv;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    home.packages = with pkgs; [
      neovim-remote
      nvim-pdenv
      # viewers
      ghostscript # see pdf
      imagemagick # see images
    ];
  };
}
