{
  description = "Example home-manager from non-nixos system";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = { self, ... }@inputs: {
    homeConfigurations = {
      darwin = inputs.home-manager.lib.homeManagerConfiguration {
        configuration = { pkgs, config, ... }:
        {
          home.stateVersion = "20.09";
          home.packages = with pkgs; [
            htop
          ];
        };
        system = "x86_64-darwin";
        homeDirectory = "/Users/chernand";
        username = "chernand";
      };
    };
  };
}
