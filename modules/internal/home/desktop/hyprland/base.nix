{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf optionals;
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = cfg.enable or false;
  autologin = cfg.autologin or { };
  remote = cfg.remote or { };
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
      hyprpaper
      grim
      slurp
      swappy
      wl-clipboard
      cliphist
      pavucontrol
      pwvucontrol
      playerctl
      nautilus
      sushi
      xfce.tumbler
      brightnessctl
      networkmanagerapplet
      blueman
      polkit_gnome
      wayvnc
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      settings = {
        "$mod" = "SUPER";
        "$meh" = "CTRL SHIFT ALT";
        "$hyper" = "CTRL SHIFT ALT SUPER";
        "$terminal" = cfg.terminal or "ghostty";
        "$launcher" = cfg.launcher or "rofi -show drun";

        monitor = [
          ",preferred,auto,1"
        ];

        exec-once = [
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

  };
}
