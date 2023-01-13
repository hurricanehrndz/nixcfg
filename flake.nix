{
  description = "Test Darwin Config";

  nixConfig.extra-experimental-features = "nix-command flakes";

  inputs = {
    # Package sets
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-22.11-darwin";

    # flake helpers
    flake-utils.url = "github:numtide/flake-utils";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    utils.inputs.flake-utils.follows = "flake-utils";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-stable-darwin";
  };

  outputs =
    { self
    , darwin
    , nixpkgs-stable-darwin
    , flake-utils
    , utils
    , ...
    } @inputs:
    utils.lib.mkFlake {
      inherit self inputs;

      channelsConfig.allowUnfree = true;

      channels.nixpkgs-stable-darwin = {};

      hosts.CarlosslMachine = {
        output = "darwinConfigurations";
        builder = darwin.lib.darwinSystem;
        system = "aarch64-darwin";
        modules = [ ./hosts/CarlosslMachine ];
        channelName = "nixpkgs-stable-darwin";
      };
    };
}
