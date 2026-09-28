{
  config,
  lib,
  ...
}:
{
  # Monitors are not declared here: the shell's display panel writes
  # $XDG_CONFIG_HOME/hypr/monitors.lua after scale confirmation (hrndz-shell's
  # bin/monitor), so that file stays user-owned. It loads from extraConfig,
  # after the fallback rule below, so its per-output rules take precedence.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland = {
      settings.monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      };

      extraConfig = ''
        local monitors = (os.getenv("XDG_CONFIG_HOME") or ${
          lib.generators.toLua { } config.xdg.configHome
        }) .. "/hypr/monitors.lua"
        local monitors_file = io.open(monitors, "r")
        if monitors_file then
          monitors_file:close()
          dofile(monitors)
        end
      '';
    };
  };
}
