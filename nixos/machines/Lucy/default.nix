{ self
, config
, lib
, pkgs
, system
, inputs
, ...
}:
let
  username = "hurricane";
in
{
  _module.args.username = username;
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = lib.mkDefault 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "kvm-intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
  boot.kernelParams = [ "kvm.ignore_msrs=1" ];
  networking.domain = "hrndz.ca";

  services.WakeOnLan = {
    enable = true;
    macAddress = "b8:85:84:b1:6a:eb";
  };

  services.gnomeDesktop = {
    enable = true;
    inherit username;
  };

  environment = {
    systemPackages = with pkgs; [
      virt-viewer
    ];
  };

  services.flatpak.enable = true;

  networking.firewall.allowedTCPPorts = [ 43389 5901 ];

  system.stateVersion = "23.11";
}
# vim: set et sw=2 :
