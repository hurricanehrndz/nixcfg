{
  description = "Living decription of personal dev environment and life support systems";

  # nixConfig.extra-experimental-features = "nix-command flakes";

  inputs = {
    # Package sets
    nixpkgs.follows = "nixos-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-pr211321.url = "github:mstone/nixpkgs/darwin-fix-vscode-lldb";
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
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # devshell
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.flake-utils.follows = "flake-utils";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv";

    # neovim
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly.inputs.nixpkgs.follows = "nixpkgs";
    go-nvim-src.url = "github:ray-x/go.nvim";
    go-nvim-src.flake = false;
    gitsigns-src.url = "github:lewis6991/gitsigns.nvim";
    gitsigns-src.flake = false;
    nvim-colorizer-src.url = "github:NvChad/nvim-colorizer.lua";
    nvim-colorizer-src.flake = false;
    nvim-window-src.url = "gitlab:yorickpeterse/nvim-window";
    nvim-window-src.flake = false;
    nvim-osc52-src.url = "github:ojroques/nvim-osc52";
    nvim-osc52-src.flake = false;
    telescope-nvim-src.url = "github:nvim-telescope/telescope.nvim";
    telescope-nvim-src.flake = false;
    nvim-treesitter-src.url = "github:nvim-treesitter/nvim-treesitter";
    nvim-treesitter-src.flake = false;
    mini-nvim-src.url = "github:echasnovski/mini.nvim";
    mini-nvim-src.flake = false;
    nvim-lspconfig-src.url = "github:neovim/nvim-lspconfig";
    nvim-lspconfig-src.flake = false;
    nvim-guihua-src.url = "github:ray-x/guihua.lua";
    nvim-guihua-src.flake = false;
    swiftformat-src.url = "github:nicklockwood/SwiftFormat?rev=a5d58763da90d8240b2a0f7f2b57da29438a0530";
    swiftformat-src.flake = false;
    swiftlint-src.url = "github:realm/SwiftLint?rev=eb85125a5f293de3d3248af259980c98bc2b1faa";
    swiftlint-src.flake = false;

    # golang support tools
    go-enum-src.url = "github:abice/go-enum";
    go-enum-src.flake = false;
    gomvp-src.url = "github:abenz1267/gomvp";
    gomvp-src.flake = false;
    json-to-struct-src.url = "github:tmc/json-to-struct";
    json-to-struct-src.flake = false;

    # pypi packages
    yamllint-src.url = "github:adrienverge/yamllint";
    yamllint-src.flake = false;
    yamlfixer-src.url = "github:opt-nc/yamlfixer";
    yamlfixer-src.flake = false;

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
      ./home/configuration.nix
      ./packages

      inputs.devshell.flakeModule
      inputs.devenv.flakeModule
    ];

    systems = ["aarch64-darwin"];

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
        nameToValue = name: import (./shells + "/${name}.nix") {inherit pkgs inputs;};
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
