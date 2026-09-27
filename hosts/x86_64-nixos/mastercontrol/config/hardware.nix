{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

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
      "/var/lib/containers"
      "/backups"
    ];
  };

  services.fstrim.enable = true;

  environment.systemPackages = with pkgs; [
    lm_sensors
    parted
    smartmontools
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  hrndz.hardware = {
    gpu.vendor = "amd";
    razerLeviathanV2X.enable = true;
  };
}
