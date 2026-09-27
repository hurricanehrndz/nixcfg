{
  config,
  lib,
  ...
}:
let
  inherit (import ./_lib.nix { inherit lib; }) bindWith exec;

  # Volume and brightness keys show the shell's OSD after the change.
  cmd =
    command: kind: exec (command + lib.optionalString (kind != null) " && hrndz-shell osd ${kind}");
  held =
    keys: description: command: kind:
    bindWith {
      locked = true;
      repeating = true;
    } keys description (cmd command kind);
  once =
    keys: description: command: kind:
    bindWith { locked = true; } keys description (cmd command kind);

  sink = "@DEFAULT_AUDIO_SINK@";
  source = "@DEFAULT_AUDIO_SOURCE@";
  kbd = "brightnessctl -d '*::kbd_backlight' set";
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.bind = [
      (held "XF86AudioRaiseVolume" "Volume up" "wpctl set-volume -l 1 ${sink} 5%+" "volume")
      (held "XF86AudioLowerVolume" "Volume down" "wpctl set-volume ${sink} 5%-" "volume")
      (held "ALT + XF86AudioRaiseVolume" "Volume up precise" "wpctl set-volume -l 1 ${sink} 1%+" "volume")
      (held "ALT + XF86AudioLowerVolume" "Volume down precise" "wpctl set-volume ${sink} 1%-" "volume")
      (once "XF86AudioMute" "Mute" "wpctl set-mute ${sink} toggle" "volume")
      (once "XF86AudioMicMute" "Mute microphone" "wpctl set-mute ${source} toggle" "microphone")

      (held "XF86MonBrightnessUp" "Brightness up" "brightnessctl -e4 -n2 set 5%+" "brightness")
      (held "XF86MonBrightnessDown" "Brightness down" "brightnessctl -e4 -n2 set 5%-" "brightness")
      (held "ALT + XF86MonBrightnessUp" "Brightness up precise" "brightnessctl -e4 -n2 set 1%+"
        "brightness"
      )
      (held "ALT + XF86MonBrightnessDown" "Brightness down precise" "brightnessctl -e4 -n2 set 1%-"
        "brightness"
      )
      (held "SHIFT + XF86MonBrightnessUp" "Brightness maximum" "brightnessctl set 100%" "brightness")
      (held "SHIFT + XF86MonBrightnessDown" "Brightness minimum" "brightnessctl set 1%" "brightness")

      (held "XF86KbdBrightnessUp" "Keyboard brightness up" "${kbd} 10%+" null)
      (held "XF86KbdBrightnessDown" "Keyboard brightness down" "${kbd} 10%-" null)

      (once "XF86AudioNext" "Next track" "playerctl next" null)
      (once "ALT + XF86AudioPlay" "Next track" "playerctl next" null)
      (once "XF86AudioPrev" "Previous track" "playerctl previous" null)
      (once "ALT + SHIFT + XF86AudioPlay" "Previous track" "playerctl previous" null)
      (once "XF86AudioPlay" "Play/pause" "playerctl play-pause" null)
      (once "XF86AudioPause" "Play/pause" "playerctl play-pause" null)
      (once "XF86Eject" "Eject media" "eject" null)
    ];
  };
}
