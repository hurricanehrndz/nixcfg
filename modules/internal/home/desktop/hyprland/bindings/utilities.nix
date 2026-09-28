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

      ##: Capture
      # macOS's Cmd+Shift+3/4/5, since there is no Print key. omasnap drags a
      # region or clicks a window or monitor; its preview has an Edit button.
      # The recording keys start and stop it, to ~/Videos. The other capture
      # modes are in the launcher's Capture menu.
      (shell "SUPER + SHIFT + code:12" "Screenshot screen" "screenshot screen")
      (shell "SUPER + SHIFT + code:13" "Screenshot" "screenshot")
      (shell "SUPER + SHIFT + code:14" "Screen recording" "screenrecord region --audio")
      # code:34 and code:35 are the [ and ] keys.
      (shell "SUPER + ALT + code:34" "Make webcam overlay smaller" "webcam smaller")
      (shell "SUPER + ALT + code:35" "Make webcam overlay larger" "webcam larger")

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
