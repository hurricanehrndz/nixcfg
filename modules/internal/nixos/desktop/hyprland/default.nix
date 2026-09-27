{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.hrndz.desktop.hyprland;
in
{
  options.hrndz.desktop.hyprland = {
    enable = mkEnableOption "the personal Hyprland desktop";

    # One build of the shell for the fonts, desktop-vnc and Home Manager.
    shellPackage = mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      default = pkgs.callPackage ../../../../../per-system/pkgs/by-name/hrndz-shell/package.nix {
        hyprland = config.programs.hyprland.package;
      };
    };

    # Where ambient-set keeps the video and still the screensaver, lock screen
    # and login screen share (ambient.nix). The shell reads it from there.
    ambientDir = mkOption {
      type = types.str;
      readOnly = true;
      internal = true;
      default = cfg.shellPackage.ambientDir;
    };

    # Seconds of inactivity; hypridle (Home Manager) acts on them.
    idle = {
      screensaver = mkOption {
        type = types.nullOr types.ints.positive;
        default = 240;
        description = "When the ambient video screensaver starts; null for none.";
      };
      lock = mkOption {
        type = types.ints.positive;
        default = 300;
        description = "When the session locks.";
      };
      displaysOff = mkOption {
        type = types.ints.positive;
        default = 330;
        description = "When the displays turn off.";
      };
    };

    # A fixed place rather than IP geolocation, which is wrong behind a VPN
    # and costs a lookup per refresh.
    weather.location = mkOption {
      type = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name the weather panel shows.";
          };
          latitude = mkOption { type = types.float; };
          longitude = mkOption { type = types.float; };
        };
      };
      default = {
        name = "Edmonton";
        latitude = 53.5461;
        longitude = -113.4938;
      };
      description = "Where the bar's weather widget reports for.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.hrndz.desktop.omarchy.enable;
        message = "hrndz.desktop.hyprland and hrndz.desktop.omarchy are separate desktops; enable only one.";
      }
    ];
  };
}
