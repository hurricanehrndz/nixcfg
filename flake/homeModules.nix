{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) import-tree;
in
{
  flake = {
    # No exported home modules currently
    homeModules = { };
  };
}
