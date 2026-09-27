{
  config,
  lib,
  ...
}:
let
  inherit (import ./_lib.nix { inherit lib; })
    meh
    hyper
    bind
    namedWorkspaces
    ;

  focus = target: "hl.dsp.focus({ ${target} })";
  moveWindow = target: "hl.dsp.window.move({ ${target} })";
  moveWorkspace = monitor: ''hl.dsp.workspace.move({ monitor = "${monitor}" })'';
  monitorDirs = {
    LEFT = "l";
    RIGHT = "r";
    UP = "u";
    DOWN = "d";
  };
in
{
  # Numbered on SUPER, named on Meh/Hyper as in AeroSpace.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.bind =
      # code:10 .. code:19 are the 1 .. 0 keys.
      lib.concatMap (
        workspace:
        let
          key = "code:${toString (workspace + 9)}";
          ws = toString workspace;
        in
        [
          (bind "SUPER + ${key}" "Workspace ${ws}" (focus ''workspace = "${ws}"''))
          (bind "SUPER + SHIFT + ${key}" "Move window to workspace ${ws}" (
            moveWindow ''workspace = "${ws}"''
          ))
          (bind "SUPER + SHIFT + ALT + ${key}" "Move window silently to workspace ${ws}" (
            moveWindow ''workspace = "${ws}", follow = false''
          ))
        ]
      ) (lib.range 1 10)
      ++ lib.concatMap (name: [
        (bind "${meh} + ${name}" "Workspace ${name}" (focus ''workspace = "name:${name}"''))
        (bind "${hyper} + ${name}" "Move window to workspace ${name}" (
          moveWindow ''workspace = "name:${name}"''
        ))
      ]) namedWorkspaces
      ++ [
        (bind "SUPER + S" "Toggle scratchpad" ''hl.dsp.workspace.toggle_special("scratchpad")'')
        (bind "SUPER + ALT + S" "Move window to scratchpad" (
          moveWindow ''workspace = "special:scratchpad", follow = false''
        ))

        (bind "SUPER + TAB" "Next workspace" (focus ''workspace = "e+1"''))
        (bind "SUPER + SHIFT + TAB" "Previous workspace" (focus ''workspace = "e-1"''))
        (bind "SUPER + CTRL + TAB" "Former workspace" (focus ''workspace = "previous"''))
        (bind "ALT + TAB" "Former workspace" (focus ''workspace = "previous"''))
        (bind "SUPER + mouse_down" "Next workspace" (focus ''workspace = "e+1"''))
        (bind "SUPER + mouse_up" "Previous workspace" (focus ''workspace = "e-1"''))

        ##: Monitors
        (bind "ALT + SHIFT + TAB" "Move workspace to next monitor" (moveWorkspace "+1"))
        (bind "CTRL + ALT + TAB" "Focus next monitor" (focus ''monitor = "+1"''))
        (bind "CTRL + ALT + SHIFT + TAB" "Focus previous monitor" (focus ''monitor = "-1"''))
      ]
      ++ lib.mapAttrsToList (
        key: dir: bind "SUPER + SHIFT + ALT + ${key}" "Move workspace to monitor ${dir}" (moveWorkspace dir)
      ) monitorDirs;
  };
}
