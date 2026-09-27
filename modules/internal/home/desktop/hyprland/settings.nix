{
  config,
  lib,
  ...
}:
let
  inherit (config.home.pointerCursor) name size;
  env = lib.mapAttrsToList (
    var: value: {
      _args = [
        var
        value
      ];
    }
  );
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      env = env {
        XCURSOR_THEME = name;
        XCURSOR_SIZE = toString size;
        HYPRCURSOR_THEME = name;
        HYPRCURSOR_SIZE = toString size;

        # Prefer Wayland everywhere, falling back to X11.
        GDK_BACKEND = "wayland,x11,*";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QPA_PLATFORMTHEME = "gtk3";
        MOZ_ENABLE_WAYLAND = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        OZONE_PLATFORM = "wayland";
        XDG_SESSION_TYPE = "wayland";

        # Screen sharing portals match on these.
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
      };

      # https://wiki.hypr.land/Configuring/Basics/Variables/#input
      config = {
        input = {
          kb_layout = "us";
          # Caps Lock is Compose; both Shifts set Caps Lock, and the next lone
          # Shift releases it, so a misfire clears itself.
          kb_options = "compose:caps,shift:both_capslock_cancel";
          follow_mouse = 1;
          sensitivity = 0;

          repeat_rate = 40;
          repeat_delay = 250;
          numlock_by_default = true;

          # Mouse wheel scrolls the content, not the viewport (macOS direction).
          natural_scroll = true;

          touchpad = {
            natural_scroll = false;
            clickfinger_behavior = true;
            scroll_factor = 0.4;
          };
        };

        misc = {
          key_press_enables_dpms = true;
          mouse_move_enables_dpms = true;
        };

        xwayland.force_zero_scaling = true;
        ecosystem.no_update_news = true;
      };
    };
  };
}
