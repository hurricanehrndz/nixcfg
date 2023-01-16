{
  description = "Test Darwin Config";

  nixConfig.extra-experimental-features = "nix-command flakes";

  inputs = {
    # Package sets
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-22.11-darwin";

    # flake helpers
    flake-parts.url = "github:hercules-ci/flake-parts";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        darwinConfigurations.CarlosslMachine = inputs.darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/CarlosslMachine
            {
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
      };
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "aarch64-darwin"
      ];
    };
}
