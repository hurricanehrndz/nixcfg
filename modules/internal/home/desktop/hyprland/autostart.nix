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
            -- Then start the shell: uwsm's graphical-session.target already
            -- has, but a session desktop-vnc starts has no such target.
            hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1); dbus-update-activation-environment --systemd --all; hrndz-shell start")

            hl.exec_cmd("uwsm-app -- udiskie --automount --no-notify --no-tray")
          end'')
      ];
    };
  };
}
