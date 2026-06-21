{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = (cfg.enable or false) && isLinux;
in
{
  config = mkIf enabled {
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings.mainBar = {
        layer = "top";
        position = "top";
        "modules-left" = [ "hyprland/workspaces" ];
        "modules-center" = [ "clock" ];
        "modules-right" = [
          "network"
          "pulseaudio"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          "persistent-workspaces"."*" = [
            "W"
            "A"
            "R"
            "S"
            "T"
            "V"
            "C"
            "B"
            "D"
            "F"
          ];
        };

        clock.format = "{:%a %Y-%m-%d %H:%M}";

        network = {
          "format-wifi" = "{essid} ({signalStrength}%)";
          "format-ethernet" = "{ifname}";
          "format-disconnected" = "offline";
        };

        pulseaudio = {
          format = "vol {volume}%";
          "format-muted" = "muted";
        };

        battery.format = "bat {capacity}%";
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Inter, "Symbols Nerd Font", sans-serif;
          font-size: 13px;
          min-height: 0;
        }

        window#waybar {
          background: rgba(247, 247, 247, 0.92);
          color: #242424;
          border-bottom: 1px solid #d0d0d0;
        }

        #workspaces button {
          color: #555555;
          padding: 0 10px;
        }

        #workspaces button.active {
          color: #111111;
          background: #e2e2e2;
        }

        #clock,
        #network,
        #pulseaudio,
        #battery,
        #tray {
          padding: 0 10px;
        }
      '';
    };
  };
}
