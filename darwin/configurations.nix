{
  self,
  withSystem,
  ...
}: let
  inherit
    (self)
    inputs
    ;
  inherit
    (inputs.digga.lib)
    flattenTree
    rakeLeaves
    ;

  l = inputs.nixpkgs.lib // builtins;

  darwinMachines = rakeLeaves ./machines;

  makeDarwinSystem = hostName: darwinArgs @ {system, ...}:
    withSystem system (
      ctx @ { inputs', pkgs, ... }:
        l.makeOverridable inputs.darwin.lib.darwinSystem {
          inherit system;
          pkgs = darwinArgs.pkgs or pkgs;
          modules = [
            {
              _module.args = {
                isNixos = false;
              };
              networking.hostName = hostName;
              networking.computerName = hostName;
            }
            darwinMachines.${hostName}
          ];
          specialArgs = {
            inherit
              self
              inputs
              system
              ;
            inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux isMacOS;
          };
        }
    );
in {
  flake.darwinConfigurations = {
    CarlosslMachine = makeDarwinSystem "CarlosslMachine" {
      system = "aarch64-darwin";
      modules = [];
    };
  };
}
