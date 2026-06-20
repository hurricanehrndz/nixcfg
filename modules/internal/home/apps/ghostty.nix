{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.guiDeveloper.enable {
    programs.ghostty = {
      # ghostty installed via Homebrew
      package = if isDarwin then pkgs.ghostty-bin else pkgs.unstable.ghostty;
      enable = true;
      # disable nix's integration
      enableZshIntegration = false;
      # Noctis Lux, vendored from https://github.com/EastSun5566/noctis-themes
      # (ghostty/noctis-lux). Written to $XDG_CONFIG_HOME/ghostty/themes/noctis-lux.
      themes."noctis-lux" = {
        palette = [
          "0=#003b42"
          "1=#e34e1c"
          "2=#00b368"
          "3=#f49725"
          "4=#0094f0"
          "5=#ff5792"
          "6=#00bdd6"
          "7=#8ca6a6"
          "8=#004d57"
          "9=#ff4000"
          "10=#00d17a"
          "11=#ff8c00"
          "12=#0fa3ff"
          "13=#ff6b9f"
          "14=#00cbe6"
          "15=#bbc3c4"
        ];
        background = "f6edda";
        foreground = "005661";
        cursor-color = "005661";
        selection-background = "169fb1";
        selection-foreground = "005661";
      };
      settings = {
        theme = "noctis-lux";
        window-theme = "light";
        # disable automatic injection - we do it in zsh
        shell-integration = "none";
        # background-opacity = 0.80;
        background-opacity-cells = true;
        background-blur-radius = 16;
        # window-decoration = false;
        shell-integration-features = "sudo,no-ssh-terminfo,no-ssh-env,cursor";
        clipboard-paste-protection = false;
      };
    };
  };
}
