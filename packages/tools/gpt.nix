{ writeScriptBin, pkgs, ... }:
writeScriptBin "gpt" ''
  args=( "$@" )
  ${pkgs.mods}/bin/mods -f "''${args[@]}" | ${pkgs.glow}/bin/glow
''
