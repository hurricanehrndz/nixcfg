{
  description = "Living decription of personal dev environment and life support systems";

  # nixConfig.extra-experimental-features = "nix-command flakes";

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

    # neovim
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitsigns-src = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    nvim-colorizer-src = {
      url = "github:NvChad/nvim-colorizer.lua";
      flake = false;
    };
    nvim-window-src = {
      url = "gitlab:yorickpeterse/nvim-window";
      flake = false;
    };
    nvim-osc52-src = {
      url = "github:ojroques/nvim-osc52";
      flake = false;
    };
    telescope-nvim-src = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };
    nvim-treesitter-src = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };
    mini-nvim-src = {
      url = "github:echasnovski/mini.nvim";
      flake = false;
    };
    # pypi packages
    yamllint-src = {
      url = "github:adrienverge/yamllint";
      flake = false;
    };
    yamlfixer-src = {
      url = "github:opt-nc/yamlfixer";
      flake = false;
    };

    # tmux
    extrakto-src = {
      url = "github:laktak/extrakto";
      flake = false;
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
  in (flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      ./flake-modules/homeConfigurations.nix
      ./flake-modules/sharedProfiles.nix

      ./darwin/configurations.nix
      ./home/configuration.nix
      ./packages
    ];

    systems = ["aarch64-darwin"];

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
    flake = {
      # shared importables :: may be used within system configurations for any
      # supported operating system (e.g. nixos, nix-darwin).
      sharedProfiles = rakeLeaves ./profiles;
    };
  });
}
