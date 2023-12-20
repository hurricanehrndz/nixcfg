{
  description = "Living description of personal life support systems";

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
    nixpkgs-pr259776.url = "github:Leixb/nixpkgs/rustdesk-123";

    # software
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable";
    flatpaks.inputs.nixpkgs.follows = "nixpkgs";

    # flake helpers
    flake-parts.url = "github:hercules-ci/flake-parts";
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # devshell
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    devenv.url = "github:cachix/devenv";

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

    tmux-catppuccin-src.url = "github:catppuccin/tmux";
    tmux-catppuccin-src.flake = false;
  };

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
    haumea,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./flake-modules/homeConfigurations.nix
        ./flake-modules/sharedProfiles.nix

        ./darwin/configurations.nix
        ./nixos/configurations.nix
        ./home/configuration.nix
        ./packages
        ./lib

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
          ];
        };
      in {
        _module.args = {
          inherit pkgs;
        };

        formatter = inputs'.nixpkgs.legacyPackages.alejandra;

        devShells = haumea.lib.load {
          src = ./shells;
          inputs = {
            inherit inputs inputs' pkgs;
            flake = self';
          };
        };
      };
      flake = {
        # shared importables :: may be used within system configurations for any
        # supported operating system (e.g. nixos, nix-darwin).
        sharedProfiles = self.lib.rakeLeaves ./profiles;
      };
    };
}
