{
  config,
  lib,
  ...
}:
{
  # https://wiki.hypr.land/Configuring/Basics/Window-Rules/
  # Rules apply in list order: tags are set first, then matched on.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      window_rule = [
        {
          match.class = ".*";
          suppress_event = "maximize";
        }

        # Every window gets default opacity unless a rule below drops the tag.
        {
          match.class = ".*";
          tag = "+default-opacity";
        }

        # Fix some dragging issues with XWayland.
        {
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }

        ##: Terminals
        # The universal clipboard bindings single terminals out by this tag.
        {
          match.class = "(Alacritty|kitty|com.mitchellh.ghostty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm)";
          tag = "+terminal";
        }
        {
          match.class = "(Alacritty|kitty|foot)";
          scroll_touchpad = 1.5;
        }
        {
          match.class = "com.mitchellh.ghostty";
          scroll_touchpad = 0.2;
        }

        ##: Browsers
        {
          match.class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)";
          tag = "+chromium-based-browser";
        }
        {
          match.class = "([fF]irefox|zen|librewolf)";
          tag = "+firefox-based-browser";
        }
        {
          match.tag = "chromium-based-browser";
          tag = "-default-opacity";
          tile = true;
          opacity = "1.0 0.985";
        }
        {
          match.tag = "firefox-based-browser";
          tag = "-default-opacity";
          opacity = "1.0 0.985";
        }

        # Hide screen sharing notification windows.
        {
          match.title = ".*is sharing.*";
          workspace = "special silent";
        }

        ##: Picture-in-picture
        {
          match.title = "(Picture.?in.?[Pp]icture)";
          tag = "+pip";
        }
        {
          match.tag = "pip";
          tag = "-default-opacity";
          float = true;
          pin = true;
          size = [
            600
            338
          ];
          keep_aspect_ratio = true;
          border_size = 0;
          opacity = "1 1";
          move = [
            "(monitor_w-window_w-40)"
            "(monitor_h*0.04)"
          ];
        }

        ##: Floating dialogs and utilities
        {
          match.tag = "floating-window";
          float = true;
          center = true;
          size = [
            875
            600
          ];
        }
        {
          match.class = "(org.gnome.NautilusPreviewer|org.gnome.Evince|imv|mpv|xdg-desktop-portal-gtk)";
          tag = "+floating-window";
        }
        {
          match = {
            class = "(sublime_text|DesktopEditors|org.gnome.Nautilus)";
            title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)";
          };
          tag = "+floating-window";
        }
        {
          match.class = "(Share|localsend)";
          float = true;
          center = true;
        }
        {
          match.class = "localsend";
          size = [
            1100
            700
          ];
        }
        {
          match.class = "^(1[p|P]assword)$";
          no_screen_share = true;
          tag = "+floating-window";
        }
        {
          match.class = "^(jetbrains-.*)$";
          no_follow_mouse = true;
        }

        ##: Media and games keep full opacity
        {
          match.class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|imv|org.gnome.NautilusPreviewer|qemu)$";
          tag = "-default-opacity";
          opacity = "1 1";
        }
        {
          match.class = "steam";
          float = true;
          idle_inhibit = "fullscreen";
        }
        {
          match = {
            class = "steam";
            title = "Steam";
          };
          center = true;
          size = [
            1100
            700
          ];
        }
        {
          match = {
            class = "steam";
            title = "Friends List";
          };
          size = [
            460
            800
          ];
        }
        {
          match.class = "steam.*";
          tag = "-default-opacity";
          opacity = "1 1";
        }

        # Prevent idle while a window carries this tag.
        {
          match.tag = "noidle";
          idle_inhibit = "always";
        }

        # Default opacity, after the rules above had a chance to drop the tag.
        {
          match.tag = "default-opacity";
          opacity = "0.985 0.96";
        }
      ];

      # No border animation around the slurp region picker.
      layer_rule = {
        match.namespace = "selection";
        no_anim = true;
        animation = "none";
      };
    };
  };
}
