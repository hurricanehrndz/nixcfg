{
  description = "Living description of personal dev environment and life support systems";


  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hurricanehrndz.cachix.org"
      "https://cache.nixos.org "
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hurricanehrndz.cachix.org-1:rKwB3P3FZ0T0Ck1KierCaO5PITp6njsQniYlXPVhFuA="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    # Package sets
    nixpkgs.follows = "nixos-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-pr211321.url = "github:mstone/nixpkgs/darwin-fix-vscode-lldb";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";

    # flake helpers
    flake-parts.url = "github:hercules-ci/flake-parts";
    digga = {
      url = "github:divnix/digga/home-manager-22.11";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # devshell
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv";

    # python
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

    # others
    git-fat.url = "github:hurricanehrndz/git-fat";
    # git-fat.inputs.nixpkgs.follows = "nixpkgs";

    # System tools
    snapraid-runner.url = "github:hurricanehrndz/snapraid-runner/hrndz";
    snapraid-runner.inputs.nixpkgs.follows = "nixpkgs";

    # personal dev environment
    pdenv.url = "github:hurricanehrndz/pdenv";

    # tmux
    extrakto-src.url = "github:laktak/extrakto";
    extrakto-src.flake = false;
  };

  outputs = {
    self,
    flake-parts,
    nixpkgs,
    digga,
    ...
  } @ inputs: let
    inherit (digga.lib) flattenTree rakeLeaves;
  in (flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      ./flake-modules/homeConfigurations.nix
      ./flake-modules/sharedProfiles.nix

      ./darwin/configurations.nix
      ./nixos/configurations.nix
      ./home/configuration.nix
      ./packages

      inputs.devshell.flakeModule
      inputs.devenv.flakeModule
    ];

    systems = ["aarch64-darwin" "x86_64-linux"];

    perSystem = {
      system,
      inputs',
      self',
      ...
    }: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.agenix.overlays.default
          inputs.devshell.overlays.default
          inputs.snapraid-runner.overlays.default
          inputs.poetry2nix.overlay
        ];
      };
    in {
      _module.args = {
        inherit pkgs;
      };

      formatter = inputs'.nixpkgs.legacyPackages.alejandra;

      devShells = let
        ls = builtins.readDir ./shells;
        files = builtins.filter (name: ls.${name} == "regular") (builtins.attrNames ls);
        shellNames = builtins.map (filename: builtins.head (builtins.split "\\." filename)) files;
        nameToValue = name: import (./shells + "/${name}.nix") {inherit pkgs inputs inputs';};
      in
        builtins.listToAttrs (builtins.map (name: {
            inherit name;
            value = nameToValue name;
          })
          shellNames);
    };
    flake = {
      # shared importables :: may be used within system configurations for any
      # supported operating system (e.g. nixos, nix-darwin).
      sharedProfiles = rakeLeaves ./profiles;
    };
  });
}
