{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce mkIf;
  cfg = config.hrndz.desktop.hyprland;
  hyprland = config.programs.hyprland.package;

  # The Hyprland package ships two sessions, plain and uwsm-managed, and
  # programs.hyprland lists the whole package. Only the uwsm one is offered.
  # It starts hyprland.desktop by name, which uwsm finds through
  # XDG_DATA_DIRS (/run/current-system/sw/share/wayland-sessions).
  uwsmSession =
    pkgs.runCommand "hyprland-uwsm-session"
      {
        passthru.providedSessions = [ "hyprland-uwsm" ];
      }
      ''
        mkdir -p $out/share/wayland-sessions
        ln -s ${hyprland}/share/wayland-sessions/hyprland-uwsm.desktop $out/share/wayland-sessions/
      '';
in
{
  config = mkIf cfg.enable {
    ##: Hyprland from nixpkgs
    # Home Manager writes the config to ~/.config/hypr/hyprland.lua, where the
    # stock session reads it.
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    ##: Login screen
    # Stock SDDM theme until the Phase 3 login theme lands.
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      # CEILING: forcing the list drops sessions any other module registers.
      # Fine while this is the host's only desktop (asserted against Omarchy);
      # filter the list instead if another desktop can sit alongside it.
      sessionPackages = mkForce [ uwsmSession ];
      defaultSession = "hyprland-uwsm";
    };

    ##: Portals
    # programs.hyprland adds xdg-desktop-portal-hyprland; GTK covers file pickers.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # Home Manager's gtk and dconf settings (light/dark) need the dconf service.
    programs.dconf.enable = true;
  };
}
