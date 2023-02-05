{
  description = "Test Darwin Config";

  nixConfig.extra-experimental-features = "nix-command flakes";

  inputs = {
    # Package sets
    nixpkgs.follows = "nixos-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-22.11-darwin";

    # flake helpers
    flake-parts.url = "github:hercules-ci/flake-parts";
    digga = {
      url = "github:divnix/digga/home-manager-22.11";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    nixpkgs,
    digga,
    ...
  } @ inputs: let
      inherit (digga.lib) flattenTree rakeLeaves;
    in flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./darwin/configurations.nix
      ];

      systems = [ "aarch64-darwin" ];

      perSystem = {
        system,
        inputs',
        self',
        ...
      }: {
        _module.args = {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        };
        formatter = inputs'.nixpkgs.legacyPackages.alejandra;
      };

    };
}
