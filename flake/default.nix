{ inputs, ... }:
{
  systems = import inputs.systems;

  # schemas
  flake = {
    inherit (inputs.flake-schemas) schemas;
  };

  imports = [
    # per-system
    ../per-system
  ];
}
