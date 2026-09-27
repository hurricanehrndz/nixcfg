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
  # Refreshes the agents panel's usage records (Claude Code and Codex) every
  # 15 minutes, the interval Omarchy's panel polled at. The panel itself only
  # asks for limits on open and a full rescan on refresh. The collectors read
  # the agents' own transcripts and login files and never write them.
  config =
    lib.mkIf (config.wayland.windowManager.hyprland.enable && osConfig.hrndz.tooling.ai.enable)
      {
        systemd.user.services.hrndz-agent-usage = {
          Unit.Description = "Refresh agent usage records for the desktop shell";
          Service = {
            Type = "oneshot";
            ExecStart = "${shell}/share/hrndz-shell/bin/agent-usage-update";
          };
        };

        systemd.user.timers.hrndz-agent-usage = {
          Unit.Description = "Refresh agent usage records every 15 minutes";
          Timer = {
            OnStartupSec = "1min";
            OnUnitActiveSec = "15min";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
}
