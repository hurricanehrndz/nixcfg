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
  # Omarchy desktops run nixos-unstable, which nixarchy is built against.
  desktopHostNames = [
    "Lucy"
    "mastercontrol"
  ];

  darwinHostNames = lib.concatMap (arch: subdirs (hostsPath + "/${arch}")) (
    lib.filter (lib.hasSuffix "-darwin") (subdirs hostsPath)
  );
  channelInputs =
    channel:
    if channel == "unstable" then
      {
        home-manager = inputs.home-manager-unstable;
        stylix = inputs.stylix-unstable;
      }
    else
      { inherit (inputs) home-manager stylix; };
in
{
  imports = [ inputs.easy-hosts.flakeModule ];

  easy-hosts = {
    autoConstruct = true;
    path = hostsPath;

    hosts =
      lib.genAttrs darwinHostNames (_: {
        nixpkgs = inputs.nixpkgs-darwin;
      })
      // lib.genAttrs desktopHostNames (_: {
        nixpkgs = inputs.nixos-unstable;
        specialArgs.channel = "unstable";
      });

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
            (
              {
                channel ? "stable",
                ...
              }:
              {
                imports = [ (channelInputs channel).home-manager.nixosModules.home-manager ];
              }
            )
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
        channel = "stable";
        inherit channelInputs;
      };
    };
  };
}
