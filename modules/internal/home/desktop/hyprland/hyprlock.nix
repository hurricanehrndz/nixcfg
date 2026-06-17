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
    programs.hyprlock = {
      enable = true;
      settings = {
        background = [
          {
            color = "rgba(f7f7f7ff)";
          }
        ];

        input-field = [
          {
            size = "300, 56";
            position = "0, -40";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            outline_thickness = 2;
            inner_color = "rgba(ffffffff)";
            outer_color = "rgba(8a8a8aff)";
            font_color = "rgba(242424ff)";
            placeholder_text = "<i>Password...</i>";
          }
        ];
      };
    };
  };
}
