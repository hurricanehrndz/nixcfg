{
  config,
  lib,
  osConfig,
  ...
}:
let
  shell = osConfig.hrndz.desktop.hyprland.shellPackage;
  dpms = "${shell}/share/hrndz-shell/bin/dpms";
in
{
  # hypridle owns idle: it locks after 5 minutes, turns the displays off after
  # 5.5, and locks before sleep. With inhibit_sleep = 3 it holds logind's sleep
  # delay (InhibitDelayMaxSec in the NixOS module) until the session reports
  # locked, so the screen is never shown unlocked on wake. The shell's
  # stay-awake toggle blocks it with a systemd idle inhibitor, which hypridle
  # honours.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "${lib.getExe shell} lock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "${dpms} on";
          inhibit_sleep = 3;
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330;
            on-timeout = "${dpms} off";
            on-resume = "${dpms} on";
          }
        ];
      };
    };

    # The night light the shell toggles over hyprsunset's IPC.
    services.hyprsunset.enable = true;
  };
}
