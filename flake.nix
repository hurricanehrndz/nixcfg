{
  description = "Example home-manager from non-nixos system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = { self, ... }@inputs:
  let
    neovim-nightly-overlay = inputs.neovim-nightly-overlay.overlay;
  in
  {
    # `internal` isn't a known output attribute for flakes. It is used here to contain
    # anything that isn't meant to be re-usable.
    internal = {
      homeConfigurations = {
        linux = inputs.home-manager.lib.homeManagerConfiguration {
          configuration = { pkgs, config, ... }:
          {
            imports = [
              # custom modules following home-manager pattern
              (import ./home/modules/programs)
              # abstraction on home-manager modules - keep it dry
              (import ./home/configs)
              # logical grouped configs
              (import ./home/profiles)
              # import host config
              (import ./home/hosts/ryzen-vmm01.nix)
            ];
            nixpkgs = {
              config.allowUnfree = true;
              overlays = [
                self.overlay
                neovim-nightly-overlay
              ];
            };
          };
          system = "x86_64-linux";
          homeDirectory = "/home/users/hurricanehrndz";
          username = "hurricanehrndz";
        };
      };
    };

    overlay = import ./nix/pkgs/packages.nix;
  };
}
