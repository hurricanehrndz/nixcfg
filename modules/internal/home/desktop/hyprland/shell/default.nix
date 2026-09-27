{
  config,
  lib,
  osConfig,
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
      Service.RestartSec = 1;
    };

    home.packages = [ shell ];
  };
}
