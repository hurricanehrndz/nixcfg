{ inputs, ... }:
{
  systems = import inputs.systems;

  # original flake attributes here.
  flake = {
    # define schemas
    inherit (inputs.flake-schemas) schemas;
  };

  imports = [
    # lib exports
    ./lib

    # per-system
    ../per-system

    # hosts
    ../hosts

    # darwinModules
    ./darwinModules.nix

    # homeModules
    ./homeModules.nix
  ];
}
