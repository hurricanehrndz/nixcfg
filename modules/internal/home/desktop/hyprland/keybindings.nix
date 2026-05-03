{
  bind = [
    # Focus, matching AeroSpace h/j/k/l.
    "$aero, H, movefocus, l"
    "$aero, J, movefocus, d"
    "$aero, K, movefocus, u"
    "$aero, L, movefocus, r"

    # Move windows, using SUPER as the Linux equivalent of macOS cmd.
    "$aeroMove, H, movewindow, l"
    "$aeroMove, J, movewindow, d"
    "$aeroMove, K, movewindow, u"
    "$aeroMove, L, movewindow, r"

    # Resize, matching AeroSpace minus/equal intent.
    "$aero, Minus, resizeactive, -50 0"
    "$aero, Equal, resizeactive, 50 0"
    "$aero, Slash, layoutmsg, togglesplit"
    "$aero, Comma, layoutmsg, swapsplit"

    # Workspace back-and-forth, matching alt-tab intent.
    "ALT, Tab, workspace, previous"
    "ALT SHIFT, Tab, movecurrentworkspacetomonitor, +1"

    # Terminal, launcher, session controls.
    "$mod, Return, exec, $terminal"
    "$mod, D, exec, $launcher"
    "$mod, Q, killactive"
    "$mod, M, exit"
    "$mod, F, fullscreen"
    "$mod, Space, togglefloating"
    "$mod, L, exec, hyprlock"
    "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

    # Screenshots.
    ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
    "SHIFT, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"

    # Named workspaces mirror the AeroSpace config.
    "$aero, W, workspace, name:W"
    "$aero, A, workspace, name:A"
    "$aero, R, workspace, name:R"
    "$aero, S, workspace, name:S"
    "$aero, T, workspace, name:T"
    "$aero, V, workspace, name:V"
    "$aero, C, workspace, name:C"
    "$aero, B, workspace, name:B"
    "$aero, D, workspace, name:D"
    "$aero, F, workspace, name:F"

    "$aeroMove, W, movetoworkspace, name:W"
    "$aeroMove, A, movetoworkspace, name:A"
    "$aeroMove, R, movetoworkspace, name:R"
    "$aeroMove, S, movetoworkspace, name:S"
    "$aeroMove, T, movetoworkspace, name:T"
    "$aeroMove, V, movetoworkspace, name:V"
    "$aeroMove, C, movetoworkspace, name:C"
    "$aeroMove, B, movetoworkspace, name:B"
    "$aeroMove, D, movetoworkspace, name:D"
    "$aeroMove, F, movetoworkspace, name:F"
  ];

  bindm = [
    "$mod, mouse:272, movewindow"
    "$mod, mouse:273, resizewindow"
  ];
}
