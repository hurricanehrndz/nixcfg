{ lib, ... }:

{
  imports = [
    ./common.nix
    ./development.nix
  ];

  config.hurricane.profiles.common.enable = lib.mkDefault true;
}
