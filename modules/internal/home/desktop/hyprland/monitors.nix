{
  config,
  lib,
  ...
}:
{
  # Monitors are not declared here: the shell's display panel (Phase 2)
  # writes $XDG_CONFIG_HOME/hypr/monitors.lua at runtime, so that file stays
  # user-owned. It loads from extraConfig because extraConfig is the only part
  # rendered after the fallback rule below, which it must override.
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
