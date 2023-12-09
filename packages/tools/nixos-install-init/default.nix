{
  writeScriptBin,
  ...
}: let
  nixos-install-init-src = builtins.readFile ./script.sh;
in
  writeScriptBin "nixos-install-init" ''
  ${nixos-install-init-src}
  ''
