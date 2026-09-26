{
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.lix.systems"
      "https://hurricanehrndz.cachix.org"
      "https://cache.numtide.com"
      "https://nixarchy.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "hurricanehrndz.cachix.org-1:rKwB3P3FZ0T0Ck1KierCaO5PITp6njsQniYlXPVhFuA="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nixarchy.cachix.org-1:05JOuIlsQOWY2/5DQMq7JEA1hwlhgvmMWowMfka8mMM="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIITemDosxrE9/Kb+PfYvE="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  inputs = {
    # Package sets
    # nixos
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Browser packages that have not landed in nixpkgs yet.
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixos-unstable";
    # nix-darwin
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # default pkg set
    nixpkgs.follows = "nixos-stable";

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
    devshell.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # secrets
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # extended management
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Omarchy desktop, vendored for NixOS. Only the package (and its tested
    # Hyprland) is used; nixarchy's modules and app installer are not imported.
    # nixpkgs is deliberately not followed so builds hit nixarchy's cache.
    nixarchy.url = "github:olafkfreund/nixarchy/v4.0.4-1";

    # System tools
    snapraid-runner.url = "github:hurricanehrndz/snapraid-runner/v2.0.0";
    snapraid-runner.inputs.nixpkgs.follows = "nixpkgs";
    # formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # zsh plugins
    zephyr-zsh-src = {
      url = "github:mattmc3/zephyr";
      flake = false;
    };
    evalcache-zsh-src = {
      url = "github:mroth/evalcache";
      flake = false;
    };

    # ghostty themes (vendored; not built into ghostty)
    noctis-themes-src = {
      url = "github:EastSun5566/noctis-themes";
      flake = false;
    };

    # personalized neovim
    # nixpkgs is deliberately not followed so builds hit hurricanehrndz.cachix.org.
    pdenv.url = "github:hurricanehrndz/pdenv";

    # coding agents
    pi.url = "github:lukasl-dev/pi.nix";
    pi.inputs.nixpkgs.follows = "nixos-unstable";
    pi.inputs.nixpkgs-x86_64-darwin.follows = "nixpkgs-darwin";
    # nixpkgs is deliberately not followed so builds hit cache.numtide.com.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # bootstrap flag
    bootstrap.url = "github:boolean-option/false";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } { imports = [ ./flake ]; };
}
