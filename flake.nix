{
  description = "Example home-manager from non-nixos system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hardware stuff
    nixGL = {
      url = "github:guibou/nixGL";
      flake = false;
    };
  };

  outputs = { self, ... }@inputs:
    with inputs.nixpkgs.lib;
    let
      neovim-overlay = inputs.neovim-nightly.overlay;
      mkHomeConfig = name:
        { configName ? name, username, homeDirectory, system }:
        nameValuePair name (inputs.home-manager.lib.homeManagerConfiguration {
          inherit system username homeDirectory;
          configuration = { ... }: {
            imports = [
              # custom modules following home-manager pattern
              (import ./home/modules)
              # abstraction on home-manager modules - keep it dry
              (import ./home/configs)
              # logical grouped configs
              (import ./home/profiles)
              # import host config
              (import (./home/hosts + "/${configName}.nix"))
            ];
            nixpkgs = {
              config.allowUnfree = true;
              config.allowUnsupportedSystem = true;
              overlays = (attrValues inputs.self.overlays)
                ++ [ neovim-overlay ];
            };
          };
        });
    in {
      # `internal` isn't a known output attribute for flakes. It is used here to contain
      # anything that isn't meant to be re-usable.
      internal = {
        homeConfigs = mapAttrs' mkHomeConfig {
          ryzen-vmm01 = {
            system = "x86_64-linux";
            username = "hurricanehrndz";
            homeDirectory = "/home/hurricanehrndz";
          };
          macbook-pro = {
            system = "x86_64-darwin";
            username = "chernand";
            homeDirectory = "/Users/chernand";
          };
        };
      };

      overlays = listToAttrs (map (name: {
        name = removeSuffix ".nix" name;
        value = import (./nix/overlays + "/${name}") inputs;
      }) (attrNames (builtins.readDir ./nix/overlays)));

      # home-manager configs
      ryzen-vmm01 = self.internal.homeConfigs.ryzen-vmm01.activationPackage;
      macbook-pro = self.internal.homeConfigs.macbook-pro.activationPackage;
    };
}
