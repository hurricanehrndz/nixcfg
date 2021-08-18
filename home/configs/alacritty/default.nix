{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.alacritty;
  key_bindings = (import ./keybinds.nix {}).key_bindings;
in {
  options.hurricane.configs.alacritty = { enable = mkEnableOption "Awesome alacritty configuration"; };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        inherit key_bindings;
        # alt_send_esc = true;
        env = { TERM = "xterm-256color"; };
        background_opacity = 0.98;
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [ "--login" "-c" "tmux new-session -A -s main" ];
        };
        font = {
          normal = {
            family = "SauceCodePro Nerd Font";
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
            black = "0x1e2127";
            red = "0xe06c75";
            green = "0x98c379";
            yellow = "0xd19a66";
            blue = "0x61afef";
            magenta = "0xc678dd";
            cyan = "0x56b6c2";
            white = "0xabb2bf";
          };

          # Bright colors
          bright = {
            black = "0x5c6370";
            red = "0xe06c75";
            green = "0x98c379";
            yellow = "0xd19a66";
            blue = "0x61afef";
            magenta = "0xc678dd";
            cyan = "0x56b6c2";
            white = "0xffffff";
          };
        };
      };
    };
  };
}

