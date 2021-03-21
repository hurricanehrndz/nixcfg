{
  description = "Example home-manager from non-nixos system";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = { self, ... } @ inputs:
    with inputs.nixpkgs.lib;
    let
      forEachSystem = genAttrs [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      pkgsBySystem = forEachSystem (system:
        import inputs.nixpkgs {
          inherit system;
        }
      );
    in
    {
      # `internal` isn't a known output attribute for flakes. It is used here to contain
      # anything that isn't meant to be re-usable.
      internal = {
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


          linux = inputs.home-manager.lib.homeManagerConfiguration {
            configuration = { pkgs, config, ... }:
            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [ self.overlay ];
              };
              home.stateVersion = "20.09";
              home.packages = with pkgs; [
                htop
                sheldon
              ];
            };
            system = "x86_64-linux";
            homeDirectory = "/home/users/hurricanehrndz";
            username = "hurricanehrndz";
          };
        };
      };

      overlay = final: prev: (import ./nix/pkgs/packages.nix) final prev;
    };
}
