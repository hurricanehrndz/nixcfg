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

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];

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

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  me.hardware.gpu.vendor = "intel";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
