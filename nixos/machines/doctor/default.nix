{
  self,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # ./hardware-configuration.nix
    ./users.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.domain = "hrndz.ca";

  # networking = {
  #   nat = {
  #     enable = true;
  #     internalInterfaces = ["ve-+"];
  #     externalInterface = "enp0s31f6";
  #   };
  # };

  environment = {
    systemPackages = with pkgs; [
    ];
  };

  system.stateVersion = "23.11";
}
# vim: set et sw=2 :

