{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
in
{
  config = mkIf config.hrndz.desktop.hyprland.enable {
    environment.sessionVariables = {
      XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };

    # The terminal the bindings launch, through xdg-terminal-exec.
    xdg.terminal-exec = {
      enable = true;
      settings.default = mkDefault [ "com.mitchellh.ghostty.desktop" ];
    };

    # What the Hyprland config and its bindings call.
    environment.systemPackages = with pkgs; [
      btop
      brightnessctl
      nautilus
      playerctl
      udiskie
      wl-clipboard
      xdg-utils

      glib
      gsettings-desktop-schemas
      gnome-themes-extra
      adwaita-icon-theme

      grim
      speedtest-cli
    ];
  };
}
