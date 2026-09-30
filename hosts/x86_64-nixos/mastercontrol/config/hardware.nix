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

  # amdgpu in the initrd: the boot splash comes up at native resolution.
  hardware.amdgpu.initrd.enable = true;

  hrndz.hardware = {
    gpu.vendor = "amd";
    razerLeviathanV2X = {
      enable = true;
      rgb.enable = true;
    };
    # The LG 27GN950-B's Sphere Lighting.
    openrgb.lights.monitor = {
      label = "Monitor";
      device = "LG 27GN950-B Monitor";
      usbId = "043e:9a8a";
      modes = [
        {
          id = "static";
          label = "Static";
          args = [
            "-m"
            "Static"
            "-c"
            "@color@"
          ];
        }
        {
          id = "spectrum";
          label = "Spectrum";
          args = [
            "-m"
            "Spectrum Cycle"
          ];
        }
        {
          id = "rainbow";
          label = "Rainbow";
          args = [
            "-m"
            "Rainbow Wave"
          ];
        }
        {
          id = "off";
          label = "Off";
          args = [
            "-m"
            "Off"
          ];
        }
      ];
    };
  };
}
