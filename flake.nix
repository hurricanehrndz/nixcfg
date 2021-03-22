{
  description = "Example home-manager from non-nixos system";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = { self, ... }@inputs:
  {
    # `internal` isn't a known output attribute for flakes. It is used here to contain
    # anything that isn't meant to be re-usable.
    internal = {
      homeConfigurations = {
        linux = inputs.home-manager.lib.homeManagerConfiguration {
          configuration = { pkgs, config, ... }:
          {
            imports = [ (import ./home/modules/programs) ];
            nixpkgs = {
              config.allowUnfree = true;
              overlays = [ self.overlay ];
            };
            home.stateVersion = "20.09";
            home.packages = with pkgs; [
              htop
            ];
            programs.sheldon = {
              enable = true;
              settings = {
                shell = "zsh";
              };
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
