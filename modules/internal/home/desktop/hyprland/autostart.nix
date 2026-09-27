{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.on = {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            -- Hand the whole session environment, including the env set in
            -- this config, to systemd and D-Bus activated services.
            hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
            hl.exec_cmd("dbus-update-activation-environment --systemd --all")

            hl.exec_cmd("hrndz-shell start")
            hl.exec_cmd("uwsm-app -- udiskie --automount --no-notify --no-tray")
          end'')
      ];
    };
  };
}
