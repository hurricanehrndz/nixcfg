{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.hrndz.desktop.hyprland;
in
{
  options.hrndz.desktop.hyprland.enable = mkEnableOption "the personal Hyprland desktop";

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.hrndz.desktop.omarchy.enable;
        message = "hrndz.desktop.hyprland and hrndz.desktop.omarchy are separate desktops; enable only one.";
      }
    ];
  };
}
