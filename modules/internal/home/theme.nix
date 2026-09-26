{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  cfg = osConfig.hrndz;
  inherit (cfg.theme) scheme;
in
{
  # Stylix supplies the palette; each app opts in here, and tmux reads
  # config.lib.stylix.colors directly. zellij and bat keep their official
  # Catppuccin port while the scheme is a Catppuccin flavor.
  config = mkIf cfg.roles.terminalUser.enable {
    stylix = {
      enable = true;
      autoEnable = false;
      overlays.enable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${scheme}.yaml";

      targets = {
        bat.enable = !lib.hasPrefix "catppuccin-" scheme;
        fzf.enable = true;
        lazygit.enable = true;
        ghostty = {
          enable = cfg.theme.ghostty == null;
          fonts.enable = false;
          opacity.enable = false;
        };
      };
    };

    # Sit on the terminal's own background rather than painting a box.
    programs.fzf.colors.bg = mkForce "-1";
  };
}
