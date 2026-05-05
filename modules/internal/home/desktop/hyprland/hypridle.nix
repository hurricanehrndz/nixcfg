{ lib, osConfig, ... }:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = cfg.enable or false;
in
{
  config = mkIf enabled {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 900;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
