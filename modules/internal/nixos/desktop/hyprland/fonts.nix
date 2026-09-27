{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  # The shell's icon font arrives with the shell in Phase 2.
  config = mkIf config.hrndz.desktop.hyprland.enable {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      font-awesome
      liberation_ttf
    ];

    # The families Omarchy's fontconfig picks, without its per-script rules.
    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "Liberation Sans" ];
      serif = [ "Liberation Serif" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
