{
  inputs = {
    # `flake-schemas` is a flake that provides schemas for commonly used flake outputs,
    # like `packages` and `devShells`.
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";

    # determinate nix
    determinate-nix.url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # Package sets
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fh-nixpkgs-unstable.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    fh-nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

    # index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # systems defs
    systems.url = "github:nix-systems/default";

    # default pkg set
    nixpkgs.follows = "fh-nixpkgs-unstable";

    # flake helpers
    flake-parts.url = "github:hercules-ci/flake-parts";
    easy-hosts.url = "github:tgirlcloud/easy-hosts";
    import-tree.url = "github:vic/import-tree";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    # devshell
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";

    # extended management
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # System tools
    snapraid-runner.url = "github:hurricanehrndz/snapraid-runner/hrndz";
    snapraid-runner.inputs.nixpkgs.follows = "nixpkgs";

    # encryption tools
    strongbox-src.url = "github:uw-labs/strongbox/v2.1.0";
    strongbox-src.flake = false;

    # formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } { imports = [ ./flake ]; };
}
