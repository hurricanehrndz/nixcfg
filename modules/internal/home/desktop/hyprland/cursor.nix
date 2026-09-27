{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  # NixOS ships no default cursor theme, so Hyprland would fall back to its
  # built-in one.
  config = lib.mkIf ((osConfig.hrndz.desktop.hyprland.enable or false) && isLinux) {
    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      hyprcursor.enable = true;
    };
  };
}
