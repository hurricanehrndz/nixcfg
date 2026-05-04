{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    types
    ;
  cfg = config.hrndz.desktop.hyprland;
in
{
  options.hrndz.desktop.hyprland = {
    enable = mkEnableOption "opinionated Hyprland desktop";

    autologin = {
      enable = mkEnableOption "greetd autologin into a locked Hyprland session";
      user = mkOption {
        type = types.str;
        default = config.system.primaryUser;
        description = "User for greetd's initial Hyprland autologin session.";
      };
    };

    remote = {
      enable = mkEnableOption "WayVNC startup inside the Hyprland user session";
      bind = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address passed to wayvnc.";
      };
      port = mkOption {
        type = types.port;
        default = 5900;
        description = "Port passed to wayvnc.";
      };
    };

    terminal = mkOption {
      type = types.str;
      default = "ghostty";
      description = "Terminal command used by the Home Manager Hyprland profile.";
    };

    launcher = mkOption {
      type = types.str;
      default = "rofi -show drun";
      description = "Launcher command used by the Home Manager Hyprland profile.";
    };

    theme = {
      source = mkOption {
        type = types.enum [ "omarchy" ];
        default = "omarchy";
        description = "Theme source inspiration for the Hyprland profile.";
      };
      variant = mkOption {
        type = types.enum [
          "light"
          "dark"
          "omarchy-default"
        ];
        default = "light";
        description = "Preferred theme variant.";
      };
    };
  };

  config = mkMerge [
    (mkIf config.hrndz.roles.guiDeveloper.enable {
      hrndz.desktop.hyprland.enable = mkDefault true;
    })

    (mkIf cfg.enable {
      ##: Hyprland
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      ##: Login screen - greetd + tuigreet
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${pkgs.hyprland}/bin/Hyprland";
            user = "greeter";
          };
        }
        // optionalAttrs cfg.autologin.enable {
          initial_session = {
            command = "${pkgs.hyprland}/bin/Hyprland";
            user = cfg.autologin.user;
          };
        };
      };

      ##: Portals for Wayland desktop integration
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };

      ##: Audio - PipeWire stack
      security.rtkit.enable = true;
      security.polkit.enable = true;
      services.dbus.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
      services.pulseaudio.enable = false;

      ##: Desktop support
      networking.networkmanager.enable = mkDefault true;
      hardware.bluetooth.enable = mkDefault true;
      services.blueman.enable = mkDefault true;

      environment.sessionVariables = {
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
      };
    })
  ];
}
