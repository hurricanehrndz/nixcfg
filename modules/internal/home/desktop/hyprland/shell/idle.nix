{
  config,
  lib,
  osConfig,
  ...
}:
let
  shell = osConfig.hrndz.desktop.hyprland.shellPackage;
  dpms = "${shell}/share/hrndz-shell/bin/dpms";
  ambient = "${lib.getExe shell} ipc ambient";
  timeouts = osConfig.hrndz.desktop.hyprland.idle;
in
{
  # hypridle owns idle: it starts the ambient video screensaver, locks, and
  # turns the displays off at the hrndz.desktop.hyprland.idle timeouts (4, 5
  # and 5.5 minutes by default), and locks before sleep. Any input drops the
  # screensaver. With inhibit_sleep = 3 it holds logind's sleep
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
        listener =
          lib.optional (timeouts.screensaver != null) {
            timeout = timeouts.screensaver;
            on-timeout = "${ambient} screensaver";
            on-resume = "${ambient} hideScreensaver";
          }
          ++ [
            {
              timeout = timeouts.lock;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = timeouts.displaysOff;
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
