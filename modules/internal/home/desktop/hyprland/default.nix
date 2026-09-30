{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  enabled = (osConfig.hrndz.desktop.hyprland.enable or false) && isLinux;
in
{
  # The other files in this directory each add one part of the config; they
  # all apply only while wayland.windowManager.hyprland is enabled here.
  config = mkIf enabled {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      # The NixOS module (programs.hyprland) installs Hyprland and its portal;
      # passing the same package gives the .luarc.json stubs and reload on switch.
      package = osConfig.programs.hyprland.package;
      portalPackage = null;
      # uwsm starts the session and binds it to graphical-session.target;
      # HM's own hyprland-session.target would start a second one.
      systemd.enable = false;
    };

    stylix.targets.hyprland.enable = true;

    # GTK apps follow the scheme's light/dark: GTK 3 through settings.ini, GTK 4
    # and libadwaita through the portal, which reads dconf's color-scheme.
    gtk = {
      enable = true;
      colorScheme = config.lib.stylix.colors.variant;
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
    };
  };
}
