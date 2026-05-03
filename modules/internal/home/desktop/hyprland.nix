{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf optionals;
  cfg = osConfig.me.desktop.hyprland or { };
  enabled = cfg.enable or false;
  autologin = cfg.autologin or { };
  remote = cfg.remote or { };
  keybindings = import ./hyprland/keybindings.nix;
  rules = import ./hyprland/rules.nix;
  remoteCommand = "wayvnc ${remote.bind or "127.0.0.1"} ${toString (remote.port or 5900)}";
  remoteExec =
    if (remote.enable or false) && (autologin.enable or false) then
      [ "sh -c 'hyprlock & sleep 1; exec ${remoteCommand}'" ]
    else if (remote.enable or false) then
      [ remoteCommand ]
    else
      [ ];
in
{
  config = mkIf enabled {
    home.packages = with pkgs; [
      ghostty
      rofi
      waybar
      mako
      hyprpaper
      hyprlock
      hypridle
      grim
      slurp
      swappy
      wl-clipboard
      cliphist
      pavucontrol
      pwvucontrol
      playerctl
      brightnessctl
      networkmanagerapplet
      blueman
      polkit_gnome
      wayvnc
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      settings =
        keybindings
        // rules
        // {
          "$mod" = "SUPER";
          "$aero" = "CTRL SHIFT ALT";
          "$aeroMove" = "CTRL SHIFT ALT SUPER";
          "$terminal" = cfg.terminal or "ghostty";
          "$launcher" = cfg.launcher or "rofi -show drun";

          monitor = [
            ",preferred,auto,1"
          ];

          exec-once = [
            "waybar"
            "mako"
            "hypridle"
            "wl-paste --type text --watch cliphist store"
            "wl-paste --type image --watch cliphist store"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          ]
          ++ optionals ((autologin.enable or false) && !(remote.enable or false)) [
            "hyprlock"
          ]
          ++ remoteExec;

          input = {
            kb_layout = "us";
            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
              tap-to-click = true;
            };
          };

          general = {
            gaps_in = 0;
            gaps_out = 8;
            border_size = 2;
            layout = "dwindle";
          };

          decoration = {
            rounding = 8;
            blur = {
              enabled = true;
              size = 6;
              passes = 2;
            };
          };

          animations.enabled = true;

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };
        };
    };

    xdg.configFile = {
      "hypr/hypridle.conf".text = ''
        general {
          lock_cmd = pidof hyprlock || hyprlock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
        }

        listener {
          timeout = 900
          on-timeout = loginctl lock-session
        }

        listener {
          timeout = 1200
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
        }
      '';

      "hypr/hyprlock.conf".text = ''
        background {
          color = rgba(f7f7f7ff)
        }

        input-field {
          size = 300, 56
          position = 0, -40
          monitor =
          dots_center = true
          fade_on_empty = false
          outline_thickness = 2
          inner_color = rgba(ffffffff)
          outer_color = rgba(8a8a8aff)
          font_color = rgba(242424ff)
          placeholder_text = <i>Password...</i>
        }
      '';

      "waybar/config".text = ''
        {
          "layer": "top",
          "position": "top",
          "modules-left": ["hyprland/workspaces"],
          "modules-center": ["clock"],
          "modules-right": ["network", "pulseaudio", "battery", "tray"],
          "hyprland/workspaces": {
            "format": "{name}",
            "persistent-workspaces": {
              "*": ["W", "A", "R", "S", "T", "V", "C", "B", "D", "F"]
            }
          },
          "clock": {
            "format": "{:%a %Y-%m-%d %H:%M}"
          },
          "network": {
            "format-wifi": "{essid} ({signalStrength}%)",
            "format-ethernet": "{ifname}",
            "format-disconnected": "offline"
          },
          "pulseaudio": {
            "format": "vol {volume}%",
            "format-muted": "muted"
          },
          "battery": {
            "format": "bat {capacity}%"
          }
        }
      '';

      "waybar/style.css".text = ''
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

      "rofi/config.rasi".text = ''
        configuration {
          modi: "drun,run,window";
          show-icons: true;
          terminal: "ghostty";
        }

        * {
          background: #f7f7f7;
          foreground: #242424;
          selected: #d9e8ff;
          border: #8a8a8a;
        }

        window {
          width: 40%;
          border: 1px;
          border-color: @border;
          background-color: @background;
        }

        element selected {
          background-color: @selected;
        }
      '';

      "mako/config".text = ''
        background-color=#f7f7f7
        text-color=#242424
        border-color=#8a8a8a
        border-size=1
        border-radius=8
        default-timeout=5000
      '';
    };
  };
}
