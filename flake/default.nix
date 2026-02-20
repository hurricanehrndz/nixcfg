{ inputs, ... }:
{
  systems = import inputs.systems;

  flake = { };

  imports = [
    # lib exports
    ./lib

    # per-system
    ../per-system

    # hosts
    ../hosts

    # darwinModules
    ./darwinModules.nix

    # nixosModules
    ./nixosModules.nix

    # homeModules
    ./homeModules.nix
  ];
}
