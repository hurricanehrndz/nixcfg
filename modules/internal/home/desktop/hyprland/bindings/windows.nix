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
    bindWith
    ;

  # Window management. Meh and Hyper chords mirror AeroSpace on macOS.
  arrows = {
    LEFT = "l";
    RIGHT = "r";
    UP = "u";
    DOWN = "d";
  };
  vimKeys = {
    H = "l";
    J = "d";
    K = "u";
    L = "r";
  };
  perKey = keys: f: lib.concatLists (lib.mapAttrsToList f keys);

  # code:20 and code:21 are the minus and equal keys.
  resize = x: y: "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
  steps = [
    {
      mods = "SUPER";
      size = 100;
      what = "";
    }
    {
      mods = "SUPER + ALT";
      size = 25;
      what = " a little";
    }
    {
      mods = "SUPER + CTRL";
      size = 300;
      what = " a lot";
    }
  ];
  mouse = bindWith { mouse = true; };
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings.bind = [
      (bind "SUPER + W" "Close window" "hl.dsp.window.close()")

      (bind "SUPER + J" "Toggle window split" ''hl.dsp.layout("togglesplit")'')
      (bind "SUPER + P" "Pseudo window" "hl.dsp.window.pseudo()")
      (bind "SUPER + T" "Toggle floating/tiling" ''hl.dsp.window.float({ action = "toggle" })'')
      (bind "SUPER + F" "Full screen" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')
      (bind "SUPER + ALT + F" "Full width" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
    ]
    # Meh focuses and Hyper swaps, with the arrows or h/j/k/l as in AeroSpace.
    ++ perKey (arrows // vimKeys) (
      key: dir: [
        (bind "${meh} + ${key}" "Focus ${dir}" ''hl.dsp.focus({ direction = "${dir}" })'')
        (bind "${hyper} + ${key}" "Move window ${dir}" ''hl.dsp.window.swap({ direction = "${dir}" })'')
      ]
    )
    ++ [
      (bind "${meh} + code:20" "Shrink window" (resize (-50) 0))
      (bind "${meh} + code:21" "Grow window" (resize 50 0))
      (bind "${meh} + slash" "Toggle split" ''hl.dsp.layout("togglesplit")'')
      (bind "${meh} + comma" "Swap split" ''hl.dsp.layout("swapsplit")'')
    ]
    ++ lib.concatMap (
      {
        mods,
        size,
        what,
      }:
      [
        (bind "${mods} + code:20" "Expand window left${what}" (resize (-size) 0))
        (bind "${mods} + code:21" "Shrink window left${what}" (resize size 0))
        (bind "${mods} + SHIFT + code:20" "Shrink window up${what}" (resize 0 (-size)))
        (bind "${mods} + SHIFT + code:21" "Expand window down${what}" (resize 0 size))
      ]
    ) steps
    ++ [
      (mouse "SUPER + mouse:272" "Move window" "hl.dsp.window.drag()")
      (mouse "SUPER + mouse:273" "Resize window" "hl.dsp.window.resize()")

      ##: Groups
      (bind "SUPER + G" "Toggle window grouping" "hl.dsp.group.toggle()")
      (bind "SUPER + ALT + G" "Move window out of group" "hl.dsp.window.move({ out_of_group = true })")
    ]
    ++ perKey (arrows // vimKeys) (
      key: dir: [
        (bind "SUPER + ALT + ${key}" "Move window into group ${dir}"
          ''hl.dsp.window.move({ into_group = "${dir}" })''
        )
      ]
    )
    ++ [
      (bind "SUPER + ALT + TAB" "Next window in group" "hl.dsp.group.next()")
      (bind "SUPER + ALT + SHIFT + TAB" "Previous window in group" "hl.dsp.group.prev()")
      (bind "SUPER + CTRL + LEFT" "Previous window in group" "hl.dsp.group.prev()")
      (bind "SUPER + CTRL + RIGHT" "Next window in group" "hl.dsp.group.next()")
      (bind "SUPER + ALT + mouse_down" "Next window in group" "hl.dsp.group.next()")
      (bind "SUPER + ALT + mouse_up" "Previous window in group" "hl.dsp.group.prev()")
    ]
    ++ map (
      index:
      bind "SUPER + ALT + code:${toString (index + 9)}" "Group window ${toString index}"
        "hl.dsp.group.active({ index = ${toString index} })"
    ) (lib.range 1 5);
  };
}
