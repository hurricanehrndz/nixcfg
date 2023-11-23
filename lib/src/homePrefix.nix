{inputs, ...}: let
  isDarwin = system: (builtins.elem system inputs.nixpkgs.lib.platforms.darwin);
in
  system:
    if isDarwin system
    then "/Users"
    else "/home"
