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
      package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "Catppuccin Latte";
        window-theme = "light";
        background-opacity = 0.95;
        background-blur-radius = 20;
        window-decoration = false;
      };
    };
  };
}
