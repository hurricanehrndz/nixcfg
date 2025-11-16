{ inputs, ... }:
with builtins;
let
  haumea = inputs.haumea.lib;
  lib = haumea.load {
    src = ./src;
    inputs = {
      inherit inputs haumea;
    };
  };
in
{
  flake.lib = lib;
}
