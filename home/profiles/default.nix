{ lib, ... }:

{
  imports = [
    ./common.nix
    ./development.nix
    ./desktop.nix
  ];

  config.hurricane.profiles.common.enable = lib.mkDefault true;
}
