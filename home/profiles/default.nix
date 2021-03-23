{ lib, ... }:

{
  imports = [
    ./common.nix
  ];

  config.hurricane.profiles.common.enable = lib.mkDefault true;
}
