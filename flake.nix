{
  description = "Example home-manager from non-nixos system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lua-language-server = {
      type = "github";
      owner = "sumneko";
      repo = "lua-language-server";
      ref = "master";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... }@inputs:
    with builtins;
    let
      lib = inputs.nixpkgs.lib;
      neovim-nightly-overlay = inputs.neovim-nightly-overlay.overlay;
    in {
      # `internal` isn't a known output attribute for flakes. It is used here to contain
      # anything that isn't meant to be re-usable.
      internal = {
        homeConfigurations = {
          ryzen-vmm01 = inputs.home-manager.lib.homeManagerConfiguration {
            configuration = { pkgs, config, ... }: {
              imports = [
                # custom modules following home-manager pattern
                (import ./home/modules)
                # abstraction on home-manager modules - keep it dry
                (import ./home/configs)
                # logical grouped configs
                (import ./home/profiles)
                # import host config
                (import ./home/hosts/ryzen-vmm01.nix)
              ];
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [ neovim-nightly-overlay ];
              };
            };
            system = "x86_64-linux";
            homeDirectory = "/home/hurricane";
            username = "hurricanehrndz";
          };
          macbook-pro = inputs.home-manager.lib.homeManagerConfiguration {
            configuration = { pkgs, config, ... }: {
              imports = [
                # custom modules following home-manager pattern
                (import ./home/modules)
                # abstraction on home-manager modules - keep it dry
                (import ./home/configs)
                # logical grouped configs
                (import ./home/profiles)
                # import host config
                (import ./home/hosts/macbook-pro.nix)
              ];
              nixpkgs = {
                config.allowUnfree = true;
                config.allowUnsupportedSystem = true;
                overlays = (attrValues inputs.self.overlays)
                  ++ [ neovim-nightly-overlay ];
              };
            };
            system = "x86_64-darwin";
            homeDirectory = "/Users/chernand";
            username = "chernand";
          };
        };
      };

      overlays = listToAttrs (map (name: {
        name = lib.removeSuffix ".nix" name;
        value = import (./nix/overlays + "/${name}") inputs;
      }) (attrNames (readDir ./nix/overlays)));

      # home-manager configs
      ryzen-vmm01 =
        self.interanl.homeConfigurations.ryzen-vmm01.activationPackage;
      macbook-pro =
        self.internal.homeConfigurations.macbook-pro.activationPackage;
    };
}
