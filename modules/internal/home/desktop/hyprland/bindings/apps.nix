{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ./_lib.nix { inherit lib; }) bind exec;

  # uwsm-app runs each application in its own systemd scope.
  launch =
    keys: description: command:
    bind keys description (exec "uwsm-app -- ${command}");
  browser = ''${lib.getExe' pkgs.gtk3 "gtk-launch"} "$(xdg-settings get default-web-browser)"'';
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.bind = [
      (launch "SUPER + RETURN" "Terminal" "xdg-terminal-exec")
      (launch "SUPER + SHIFT + RETURN" "Browser" browser)
      (launch "SUPER + SHIFT + B" "Browser" browser)
      (launch "SUPER + SHIFT + F" "File manager" "nautilus --new-window")
      (launch "SUPER + SHIFT + N" "Editor" ''xdg-terminal-exec "''${EDITOR:-nvim}"'')
      (launch "SUPER + CTRL + T" "Activity" "xdg-terminal-exec btop")
    ];
  };
}
