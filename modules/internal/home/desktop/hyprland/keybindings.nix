{ lib, osConfig, ... }:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz.desktop.hyprland or { };
  enabled = cfg.enable or false;
in
{
  config = mkIf enabled {
    wayland.windowManager.hyprland.settings = {
      bind = [
        # Focus, matching AeroSpace h/j/k/l.
        "$meh, H, movefocus, l"
        "$meh, J, movefocus, d"
        "$meh, K, movefocus, u"
        "$meh, L, movefocus, r"

        # Move windows, using SUPER as the Linux equivalent of macOS cmd.
        "$hyper, H, movewindow, l"
        "$hyper, J, movewindow, d"
        "$hyper, K, movewindow, u"
        "$hyper, L, movewindow, r"

        # Resize, matching AeroSpace minus/equal intent.
        "$meh, Minus, resizeactive, -50 0"
        "$meh, Equal, resizeactive, 50 0"
        "$meh, Slash, layoutmsg, togglesplit"
        "$meh, Comma, layoutmsg, swapsplit"

        # Workspace back-and-forth, matching alt-tab intent.
        "ALT, Tab, workspace, previous"
        "ALT SHIFT, Tab, movecurrentworkspacetomonitor, +1"

        # Terminal, launcher, session controls.
        "$mod, Return, exec, $terminal"
        "$mod, Space, exec, $launcher"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, F, fullscreen"
        "$mod SHIFT, Space, togglefloating"
        "$mod, L, exec, hyprlock"
        "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        # Screenshots.
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"

        # Named workspaces mirror the AeroSpace config.
        "$meh, W, workspace, name:W"
        "$meh, A, workspace, name:A"
        "$meh, R, workspace, name:R"
        "$meh, S, workspace, name:S"
        "$meh, T, workspace, name:T"
        "$meh, V, workspace, name:V"
        "$meh, C, workspace, name:C"
        "$meh, B, workspace, name:B"
        "$meh, D, workspace, name:D"
        "$meh, F, workspace, name:F"

        "$hyper, W, movetoworkspace, name:W"
        "$hyper, A, movetoworkspace, name:A"
        "$hyper, R, movetoworkspace, name:R"
        "$hyper, S, movetoworkspace, name:S"
        "$hyper, T, movetoworkspace, name:T"
        "$hyper, V, movetoworkspace, name:V"
        "$hyper, C, movetoworkspace, name:C"
        "$hyper, B, movetoworkspace, name:B"
        "$hyper, D, movetoworkspace, name:D"
        "$hyper, F, movetoworkspace, name:F"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
