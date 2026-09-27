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
