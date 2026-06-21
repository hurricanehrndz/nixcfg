{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    (inputs.import-tree ./config)
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "Lucy";
  networking.domain = "hrndz.ca";

  system.primaryUser = "hurricane";
  system.stateVersion = "25.11";
}
