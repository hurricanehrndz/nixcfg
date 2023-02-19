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

  inherit (self.nixosModules) homeManagerSettings;

  l = inputs.nixpkgs.lib // builtins;

  darwinMachines = rakeLeaves ./machines;

  defaultModules = [
    # homeManagerSettings
    inputs.home-manager.darwinModules.home-manager
  ];

  makeDarwinSystem = hostName: darwinArgs @ {system, ...}:
    withSystem system (
      ctx @ {
        inputs',
        packages,
        pkgs,
        ...
      }:
        l.makeOverridable inputs.darwin.lib.darwinSystem {
          inherit system;
          pkgs = darwinArgs.pkgs or pkgs;
          modules = [
            {
              _module.args = {
                inherit inputs';
                inherit (ctx.config) packages;
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
              packages
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
