{
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) import-tree;

  hostsPath = ../hosts;
  subdirs = path: lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir path));

  # Auto-pin every darwin host to nixpkgs-darwin, derived from the
  # `hosts/*-darwin/<host>` layout, so new hosts need no entry here.
  darwinHostNames = lib.concatMap (arch: subdirs (hostsPath + "/${arch}")) (
    lib.filter (lib.hasSuffix "-darwin") (subdirs hostsPath)
  );
in
{
  imports = [ inputs.easy-hosts.flakeModule ];

  easy-hosts = {
    autoConstruct = true;
    path = hostsPath;

    hosts = lib.genAttrs darwinHostNames (_: { nixpkgs = inputs.nixpkgs-darwin; });

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

      specialArgs = {
        isBootstrap = inputs.bootstrap.value;
      };
    };
  };
}
