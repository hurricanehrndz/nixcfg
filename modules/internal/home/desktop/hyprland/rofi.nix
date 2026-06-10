{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  mkLiteral = value: {
    _type = "literal";
    inherit value;
  };
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = (cfg.enable or false) && isLinux;
in
{
  config = mkIf enabled {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
      terminal = cfg.terminal or "ghostty";
      extraConfig = {
        modi = [
          "drun"
          "run"
          "window"
        ];
        "show-icons" = true;
      };
      theme = {
        "*" = {
          background = mkLiteral "#f7f7f7";
          foreground = mkLiteral "#242424";
          selected = mkLiteral "#d9e8ff";
          border = mkLiteral "#8a8a8a";
        };

        window = {
          width = mkLiteral "40%";
          border = 1;
          border-color = mkLiteral "@border";
          background-color = mkLiteral "@background";
        };

        "element selected" = {
          background-color = mkLiteral "@selected";
        };
      };
    };
  };
}
