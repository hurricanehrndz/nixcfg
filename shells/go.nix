{
  pkgs,
  inputs,
  ...
}: let
  inherit (inputs.devenv.lib) mkShell;
in
  mkShell {
    inherit inputs pkgs;
    modules = [
      ({pkgs, ...}: {
        languages.go.enable = true;
      })
    ];
  }
