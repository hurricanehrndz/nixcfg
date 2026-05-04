{ lib, osConfig, ... }:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = cfg.enable or false;
in
{
  config = mkIf enabled {
    wayland.windowManager.hyprland.settings.windowrulev2 = [
      "float,class:^(pavucontrol)$"
      "float,class:^(blueman-manager)$"
      "workspace name:T,class:^(com.mitchellh.ghostty)$"
      "workspace name:T,class:^(ghostty)$"
      "workspace name:F,class:^(firefox)$"
      "workspace name:C,class:^(code)$"
    ];
  };
}
