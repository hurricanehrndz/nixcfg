{ lib, osConfig, ... }:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = cfg.enable or false;
in
{
  config = mkIf enabled {
    services.mako = {
      enable = true;
      settings = {
        background-color = "#f7f7f7";
        text-color = "#242424";
        border-color = "#8a8a8a";
        border-size = 1;
        border-radius = 8;
        default-timeout = 5000;
      };
    };
  };
}
