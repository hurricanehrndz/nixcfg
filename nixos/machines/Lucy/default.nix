{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  username = "hurricane";
in {
  _module.args.username = username;
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = lib.mkDefault 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = ["kvm-intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio"];
  boot.kernelParams = ["kvm.ignore_msrs=1"];
  networking.domain = "hrndz.ca";

  virtualisation.libvirtd = {
    enable = true;
  };
  security.polkit.enable = true;

  # Wake on LAN
  systemd.network = {
    links = {
      "50-wired" = {
        matchConfig.MACAddress = "b8:85:84:b1:6a:eb";
        linkConfig = {
          NamePolicy = "kernel database onboard slot path";
          MACAddressPolicy = "persistent";
          WakeOnLan = "magic";
        };
      };
    };
  };

  services.gnomeDesktop = {
    enable = true;
    inherit username;
  };

  networking.firewall.allowedTCPPorts = [43389 5901];

  system.stateVersion = "23.11";
}
# vim: set et sw=2 :
