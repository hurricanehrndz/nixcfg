{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.desktop;
in
{
  options.hurricane.profiles.desktop = {
    enable = mkEnableOption "desktop configuration";
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        env = {
          TERM = "xterm-256color";
        };
        background_opacity = 0.98;
        shell = {
          program = "${pkgs.tmux}/bin/tmux";
          args = ["new-session" "-A" "-s" "main"];
        };
        font = {
          normal = {
            family = "FiraCode Nerd Font Mono";
            style = "Light";
          };
          size = 12;
        };
        # Colors (One Dark)
        colors = {
          # Default colors
          primary = {
            background = "0x1e2127";
            foreground = "0xabb2bf";
          };
          # Normal colors
          normal = {
            black   = "0x1e2127";
            red     = "0xe06c75";
            green   = "0x98c379";
            yellow  = "0xd19a66";
            blue    = "0x61afef";
            magenta = "0xc678dd";
            cyan    = "0x56b6c2";
            white   = "0xabb2bf";
          };

          # Bright colors
          bright = {
            black   = "0x5c6370";
            red     = "0xe06c75";
            green   = "0x98c379";
            yellow  = "0xd19a66";
            blue    = "0x61afef";
            magenta = "0xc678dd";
            cyan    = "0x56b6c2";
            white   = "0xffffff";
          };
        };
        key_bindings = [
          {
            key = "V";
            mods = "Control|Shift";
            action = "Paste";
          }
          {
            key = "C";
            mods = "Control|Shift";
            action = "Copy";
          }
          {
            key = "V";
            mods = "Super";
            action = "Paste";
          }
          {
            key = "C";
            mods = "Super";
            action = "Copy";
          }
        ];
      };
    };
  };
}
