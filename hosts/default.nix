{
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) import-tree;
in
{
  imports = [ inputs.easy-hosts.flakeModule ];

  easy-hosts = {
    autoConstruct = true;
    path = ../hosts;

    hosts = {
      HX7YG952H5.nixpkgs = inputs.nixpkgs-darwin;
      LH9KCR6DJX.nixpkgs = inputs.nixpkgs-darwin;
    };

    shared.modules = [
      (import-tree ../modules/internal/shared)
    ];

    perClass = class: {
      modules =
        with inputs;
        builtins.concatLists [
          # nixos modules
          (lib.optionals (class == "nixos") [
            (import-tree ../modules/internal/nixos)
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            disko.nixosModules.disko
            snapraid-runner.nixosModules.default
            self.nixosModules.default
          ])

          # darwin modules
          (lib.optionals (class == "darwin") [
            (import-tree ../modules/internal/darwin)
            home-manager.darwinModules.home-manager
            agenix.darwinModules.default
            self.darwinModules.default
          ])
        ];

      specialArgs = lib.optionalAttrs (class == "nixos") {
        isBootstrap = inputs.bootstrap.value;
      };
    };
  };
}
