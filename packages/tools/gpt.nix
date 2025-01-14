{writeScriptBin, pkgs, ...}:
writeScriptBin "gpt" ''
  args=( "$@" )
  ${pkgs.mods}/bin/mods "''${args[@]}" | ${pkgs.glow}/bin/glow
''
