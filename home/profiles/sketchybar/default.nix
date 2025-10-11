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
}
