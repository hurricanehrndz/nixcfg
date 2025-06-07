{
  withSystem,
  self,
  ...
}: let
  inherit (self) inputs sharedProfiles;
  inherit (self.homeModules) homeManagerSettings;
  l = inputs.nixpkgs.lib // builtins // self.lib;

  roles = import ./roles {inherit sharedProfiles nixosProfiles;};

  nixosModules = l.rakeLeaves ./modules;
  nixosMachines = l.rakeLeaves ./machines;
  nixosProfiles = l.rakeLeaves ./profiles;

  defaultModules = [
    sharedProfiles.core
    homeManagerSettings
    nixosProfiles.core
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.age
    inputs.nixos-generators.nixosModules.all-formats
  ];

  makeNixosSystem = hostname: nixosArgs @ {system, ...}:
    withSystem system (
      {
        inputs',
        pkgs,
        packages,
        ...
      }:
        l.makeOverridable l.nixosSystem {
          inherit system;
          modules =
            defaultModules
            ++ (l.recAttrValues nixosModules)
            ++ (nixosArgs.modules or [])
            ++ [
              nixosMachines.${hostname}
              {
                _module.args = {
                  inherit
                    inputs'
                    packages
                    ;
                  isNixos = true;
                };
                nixpkgs.pkgs = nixosArgs.pkgs or pkgs;
                networking.hostName = hostname;
                users.mutableUsers = false;
                home-manager.sharedModules = [{_module.args.isNixos = true;}];
              }
            ];
          specialArgs = {
            inherit
              self
              inputs
              nixosProfiles
              sharedProfiles
              roles
              system
              ;
            inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux isMacOS;
          };
        }
    );
in {
  flake.nixosModules = nixosModules;
  flake.nixosConfigurations = {
    DeepThought = makeNixosSystem "DeepThought" {
      system = "x86_64-linux";
      modules =
        (with roles; mediaserver)
        ++ [
          inputs.snapraid-runner.nixosModules.snapraid-runner
          nixosProfiles.autoUpdateContainers
        ];
    };
    Hal9000 = makeNixosSystem "Hal9000" {
      system = "x86_64-linux";
    };
    Lucy = makeNixosSystem "Lucy" {
      system = "x86_64-linux";
      modules = [
        nixosProfiles.hardware.opengl
        nixosProfiles.desktop.virtualization
      ];
      formatConfigs.install-iso.nix = {config, ...}: {
      };
    };
  };
}
