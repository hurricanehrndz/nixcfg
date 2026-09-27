# Shared by the binding files; the leading underscore keeps import-tree from
# loading it as a module.
{ lib }:
let
  inherit (lib.generators) mkLuaInline;
in
rec {
  # Chords, spelled the way AeroSpace's are on macOS.
  meh = "CTRL + SHIFT + ALT";
  hyper = "SUPER + CTRL + SHIFT + ALT";

  # One settings.bind entry: hl.bind(keys, <dispatcher>, { description, ... }).
  # dispatcher is a Lua expression.
  bindWith = opts: keys: description: dispatcher: {
    _args = [
      keys
      (mkLuaInline dispatcher)
      ({ inherit description; } // opts)
    ];
  };
  bind = bindWith { };

  # A dispatcher that runs a shell command.
  exec = command: "hl.dsp.exec_cmd(${lib.generators.toLua { } command})";
}
