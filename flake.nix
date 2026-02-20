{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs-update.cachix.org"
      "https://cache.nixos.org "
      "https://hurricanehrndz.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-update.cachix.org-1:6y6Z2JdoL3APdu6/+Iy8eZX2ajf09e4EE9SnxSML1W8="
      "hurricanehrndz.cachix.org-1:rKwB3P3FZ0T0Ck1KierCaO5PITp6njsQniYlXPVhFuA="
    ];
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # `flake-schemas` is a flake that provides schemas for commonly used flake outputs,
    # like `packages` and `devShells`.
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";

    # determinate nix cli
    determinate-nix.url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
    # determinate nix module
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # Package sets
    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-unstable-weekly.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    # nix-darwin
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    # default pkg set
    nixpkgs.follows = "nixpkgs-unstable-weekly";

    # disk config
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # systems defs
    systems.url = "github:nix-systems/default";

    # flake helpers
    flake-parts.url = "github:hercules-ci/flake-parts";
    easy-hosts.url = "github:tgirlcloud/easy-hosts";
    import-tree.url = "github:vic/import-tree";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    # devshell
    devshell.url = "github:numtide/devshell";

    # secrets
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # extended management
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # System tools
    snapraid-runner.url = "github:hurricanehrndz/snapraid-runner/hrndz";
    snapraid-runner.inputs.nixpkgs.follows = "nixpkgs";

    # formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # zsh plugins
    zephyr-zsh-src = {
      url = "github:mattmc3/zephyr";
      flake = false;
    };

    # personalized neovim
    pdenv.url = "github:hurricanehrndz/pdenv";

    # bootstrap flag
    bootstrap.url = "path:./inputs/flags/false";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } { imports = [ ./flake ]; };
}
