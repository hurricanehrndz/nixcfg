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

  # PRINT saves a region to ~/Pictures and the clipboard; SHIFT + PRINT opens
  # the region in satty for annotation.
  shot = ''dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}"; mkdir -p "$dir"; f="$dir/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"; region="$(slurp -d)" || exit 0; '';
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.bind = [
      ##: Session
      (bind "SUPER + M" "Exit session" (exec "uwsm stop"))
      (shell "SUPER + L" "Lock screen" "lock")
      (shell "SUPER + CTRL + L" "Lock screen" "lock")

      ##: Shell features (placeholders until Phase 2, see shell.nix)
      (shell "SUPER + SPACE" "Launcher" "launcher")
      (shell "SUPER + ALT + SPACE" "Menu" "menu")
      (shell "SUPER + ESCAPE" "System menu" "system-menu")
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
      (bind "PRINT" "Screenshot" (
        exec ''${shot}grim -g "$region" "$f" && wl-copy --type image/png < "$f"''
      ))
      (bind "SHIFT + PRINT" "Screenshot and annotate" (
        exec ''${shot}grim -g "$region" - | satty --filename - --output-filename "$f" --early-exit --copy-command wl-copy''
      ))
      (bind "SUPER + PRINT" "Color picker" (exec "pkill hyprpicker || hyprpicker -a"))

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
