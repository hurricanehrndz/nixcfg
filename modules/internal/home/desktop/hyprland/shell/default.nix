{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  shell = osConfig.hrndz.desktop.hyprland.shellPackage;
in
{
  # The desktop shell (per-system/pkgs/by-name/hrndz-shell), run by
  # programs.quickshell as a user service on graphical-session.target, which
  # uwsm starts. Everything bindings and menus call goes through the
  # `hrndz-shell` command it ships. The other files here write the config the
  # shell reads.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    programs.quickshell = {
      enable = true;
      # Built with QtMultimedia, for the ambient video.
      package = shell.quickshell;
      # The name `hrndz-shell ipc` looks the running instance up by.
      configs.hrndz-shell = "${shell}/share/hrndz-shell/shell";
      activeConfig = "hrndz-shell";
      systemd.enable = true;
    };

    systemd.user.services.quickshell = {
      # Stop with the session instead of outliving its compositor, and pick
      # up a new build on switch.
      Unit = {
        PartOf = [ config.programs.quickshell.systemd.target ];
        X-Restart-Triggers = [ "${shell}" ];
      };
      Service = {
        RestartSec = 1;
        # Quickshell 0.3.2 picks its network backend once at startup and never
        # retries, so a switch that restarts NetworkManager alongside the shell
        # leaves the bar showing no network until the next restart. Wait for NM
        # on the bus; '-' and the timeout keep a missing NM from blocking the
        # shell. Drop this once Quickshell reconnects a late backend itself.
        ExecStartPre = lib.mkIf osConfig.networking.networkmanager.enable "-${pkgs.glib}/bin/gdbus wait --system --timeout 15 org.freedesktop.NetworkManager";
      };
    };

    home.packages = [ shell ];
  };
}
