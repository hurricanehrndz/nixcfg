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
      enableZshIntegration = false;
      settings = {
        theme = "Catppuccin Latte";
        window-theme = "light";
        shell-integration = "none";
        background-opacity = 0.80;
        background-opacity-cells = true;
        background-blur-radius = 16;
        window-decoration = false;
      };
    };
  };
}
