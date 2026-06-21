{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # NVMe boot device: "nvme" must be present for the rootfs to come up.
  # Regenerate on the target with `nixos-generate-config` if hardware differs.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];

  # Enables DHCP on each ethernet and wireless interface starting with en*.
  hrndz.nixos.networkd-dhcp.enable = true;
  # Static IP for the network-controller host (ported from the old config).
  # Verify the interface name on the target before deploying.
  systemd.network.networks."50-enp2s0" = {
    matchConfig.Name = "enp2s0";
    networkConfig = {
      DHCP = "ipv6";
      Address = "192.168.0.15/24";
      Gateway = "192.168.0.1";
      DNS = "192.168.0.1";
    };
    dhcpV6Config.UseDNS = "yes";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
    memoryPercent = 10;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "Sun *-*-01..07 04:00:00";
    fileSystems = [
      "/"
      "/home"
      "/var"
      "/srv"
    ];
  };

  services.fstrim.enable = true;

  environment.systemPackages = with pkgs; [
    lm_sensors
    parted
    smartmontools
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
