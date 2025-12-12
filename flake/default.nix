{ inputs, ... }:
{
  systems = import inputs.systems;

  # original flake attributes here.
  flake = {
    # define schemas
    inherit (inputs.flake-schemas) schemas;
  };

  imports = [
    # per-system
    ../per-system

    # hosts
    ../hosts

    # darwinModules
    ./darwinModules.nix
  ];
}
