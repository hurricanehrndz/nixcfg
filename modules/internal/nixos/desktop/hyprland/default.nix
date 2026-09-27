{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
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
