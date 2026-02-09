{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "mpt3sas"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
    memoryPercent = 10;
  };

  # Enables DHCP on each ethernet and wireless interface starting with en*.
  hrndz.nixos.networkd-dhcp.enable = true;
  # Override specific interface with static ip
  systemd.network.networks."10-enp0s31f6" = {
    matchConfig.Name = "enp0s31f6";
    networkConfig = {
      DHCP = "ipv6";
      IPv6PrivacyExtensions = false;
      Address = "172.24.224.15/23";
      Gateway = "172.24.224.1";
      DNS = "172.24.224.1";
    };

    dhcpV6Config.UseDNS = "yes";
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
