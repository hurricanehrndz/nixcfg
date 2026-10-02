{
  config,
  lib,
  ...
}:
let
  inherit (import ./bindings/_lib.nix { inherit lib; }) namedWorkspaces;
  gpgUpdateTty = lib.optionalString config.services.gpg-agent.enable "${config.programs.gpg.package}/bin/gpg-connect-agent updatestartuptty /bye; ";
in
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
            -- gpg-agent starts at login, before the session exists, and shows
            -- pinentry for SSH on its startup display, so point it here.
            hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1); dbus-update-activation-environment --systemd --all; ${gpgUpdateTty}hrndz-shell start")

            hl.exec_cmd("uwsm-app -- udiskie --automount --no-notify --no-tray")

            -- Start on the first named workspace instead of "1". A default
            -- workspace rule would have to name the monitor.
            hl.dispatch(hl.dsp.focus({ workspace = "name:${builtins.head namedWorkspaces}" }))
          end'')
      ];
    };
  };
}
