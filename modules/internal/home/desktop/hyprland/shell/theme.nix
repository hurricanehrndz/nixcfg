{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  shell = osConfig.hrndz.desktop.hyprland.shellPackage;
  colors = config.lib.stylix.colors.withHashtag;

  # The palette the shell's surface roles fall back to.
  palette = {
    foreground = colors.base05;
    background = colors.base00;
    accent = colors.base0D;
    red = colors.base08;
    muted = colors.base04;
  };
in
{
  # The shell's colours, from the Stylix scheme. It reads these once at start;
  # a switch restarts it.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    xdg.configFile = {
      "hrndz-shell/theme/colors.toml".text = lib.concatLines (
        lib.mapAttrsToList (name: value: ''${name} = "${value}"'') palette
      );
      "hrndz-shell/theme/shell.toml".source =
        pkgs.replaceVars "${shell}/share/hrndz-shell/theme/shell.toml.in"
          {
            inherit (palette)
              foreground
              background
              accent
              red
              ;
          };
    };
  };
}
