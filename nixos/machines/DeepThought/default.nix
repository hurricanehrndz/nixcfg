{
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./filesystems.nix
    ./profles/snapraid.nix
    ./profles/samba.nix
    ./users/hurricane.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  # boot.kernelParams = ["i915.force_probe=4692"];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.extraModulePackages = with config.boot.kernelPackages; [ it87 ];
  boot.kernelModules = ["coretemp" "nct6775"];
  networking.domain = "hrndz.ca";

  services.data-access = {
    enable = true;
  };

  networking = {
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "enp0s31f6";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      recyclarr
    ];
  };

  system.stateVersion = "22.05";
}
# vim: set et sw=2 :
