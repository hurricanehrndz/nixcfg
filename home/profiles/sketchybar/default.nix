{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  programs.sketchybar = lib.mkIf isDarwin {
    enable = true;
    configType = "lua";
    includeSystemPath = true;
    config = {
      source = ./config;
      recursive = true;
    };
  };
  xdg.configFile = {
    "sketchybar/icon_map.lua".source = "${pkgs.sketchybar-app-font}/lib/sketchybar-app-font/icon_map.lua";
  };
}
