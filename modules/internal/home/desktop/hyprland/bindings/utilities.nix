{
  config,
  lib,
  ...
}:
let
  inherit (import ./_lib.nix { inherit lib; }) bind bindWith exec;

  shell =
    keys: description: args:
    bind keys description (exec "hrndz-shell ${args}");

  panels = {
    A = "audio";
    B = "bluetooth";
    W = "network";
    P = "power";
    D = "display";
  };
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.bind = [
      ##: Session
      (bind "SUPER + M" "Exit session" (exec "uwsm stop"))
      (shell "SUPER + L" "Lock screen" "lock")
      (shell "SUPER + CTRL + L" "Lock screen" "lock")

      ##: Shell features (hrndz-shell, see ../shell)
      (shell "SUPER + SPACE" "Apps and actions" "launcher")
      (bindWith { locked = true; } "XF86PowerOff" "Power menu" (exec "hrndz-shell system-menu"))
      (shell "SUPER + K" "Keybindings" "keybindings")
      (shell "SUPER + CTRL + E" "Emojis" "emoji")
      (shell "SUPER + SHIFT + SPACE" "Toggle bar" "bar")

      # xkbcommon names the comma keysym "comma"; "COMMA" does not match.
      (shell "SUPER + comma" "Dismiss last notification" "notifications dismiss-one")
      (shell "SUPER + SHIFT + comma" "Dismiss all notifications" "notifications dismiss-all")
      (shell "SUPER + ALT + comma" "Invoke last notification" "notifications invoke-last")
      (shell "SUPER + SHIFT + ALT + comma" "Notification history" "notifications history")
    ]
    ++ lib.mapAttrsToList (
      key: panel: shell "SUPER + CTRL + ${key}" "Panel: ${panel}" "panel ${panel}"
    ) panels
    ++ [
      (shell "SUPER + CTRL + ALT + D" "Panel: calendar" "panel calendar")

      ##: Screenshots
      # A region to ~/Pictures and the clipboard; SHIFT opens it in satty.
      (shell "PRINT" "Screenshot" "screenshot region")
      (shell "SHIFT + PRINT" "Screenshot and annotate" "screenshot region --edit")
      (shell "SUPER + PRINT" "Color picker" "color-picker")

      ##: Zoom
      (bind "SUPER + CTRL + Z" "Zoom in" ''
        function()
          local zoom = hl.get_config("cursor.zoom_factor") or 1
          hl.config({ cursor = { zoom_factor = zoom + 1 } })
        end'')
      (bind "SUPER + CTRL + ALT + Z" "Reset zoom" ''
        function()
          hl.config({ cursor = { zoom_factor = 1 } })
        end'')
    ];
  };
}
