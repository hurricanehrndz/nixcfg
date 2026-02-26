{
  pkgs,
  lib,
  ...
}:
let
  mkFileSystems =
    let
      mkFileSystemEntry = diskLabel: {
        "/volumes/${diskLabel}" = {
          device = "/dev/disk/by-label/${diskLabel}";
          fsType = "ext4";
          options = [
            "defaults"
            "nofail"
          ];
        };
      };
    in
    diskLabelList:
    lib.foldl' (acc: attrset: lib.recursiveUpdate acc attrset) { } (
      map mkFileSystemEntry diskLabelList
    );
in
{
  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      parted
      smartmontools
    ];
  };

  fileSystems =
    (mkFileSystems [
      "parity"
      "data1"
      "data2"
      "data3"
      "data4"
    ])
    // {
      "/volumes/cache" = {
        device = "/dev/disk/by-label/cache";
        fsType = "btrfs";
        options = [
          "defaults"
          "noatime"
          "nofail"
          "compress=zstd"
        ];
      };
      "/volumes/books" = {
        device = "/dev/disk/by-label/books";
        fsType = "btrfs";
        options = [
          "defaults"
          "noatime"
          "nofail"
          "compress=zstd"
        ];
      };
      "/volumes/storage" = {
        device = "/volumes/cache:/volumes/data*";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "nonempty"
          "allow_other"
          "use_ino"
          "cache.files=off"
          "moveonenospc=false"
          "dropcacheonclose=true"
          "minfreespace=80G"
          "category.create=ff"
          "fsname=cached_mergerfs"
        ];
      };
      "/volumes/backing_storage" = {
        device = "/volumes/data*";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "nonempty"
          "allow_other"
          "use_ino"
          "cache.files=off"
          "moveonenospc=true"
          "dropcacheonclose=true"
          "minfreespace=200G"
          "fsname=mergerfs"
        ];
      };
    };

  # smart monitoring
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -S on -T permissive -R 5! -C 197! -U 198! -W 0,46,55 -n never,q -s (S/../.././02|L/../../7/04)";
    devices = [
      {
        device = "/dev/disk/by-id/ata-ADATA_SU800_2I5020042202";
      }
      {
        device = "/dev/disk/by-id/ata-CT2000BX500SSD1_2533E9C916E0";
      }
      {
        device = "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY8FXEG";
      }
      {
        device = "/dev/disk/by-id/ata-ST12000VN0008-2PH103_ZL2PSACH";
        options = "-a -o on -S on -T permissive -v 1,raw48:54 -v 7,raw48:54 -R 5! -C 197! -U 198! -W 0,46,55 -n never,q -s (S/../.././02|L/../../7/04)";
      }
      {
        device = "/dev/disk/by-id/ata-ST12000VN0008-2PH103_ZTN18K65";
        options = "-a -o on -S on -T permissive -v 1,raw48:54 -v 7,raw48:54 -R 5! -C 197! -U 198! -W 0,46,55 -n never,q -s (S/../.././02|L/../../7/04)";
      }
      {
        device = "/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K6HJVF1L";
      }
      {
        device = "/dev/disk/by-id/ata-WDC_WD120EFBX-68B0EN0_5QKDEPLB";
      }
      {
        device = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B7283B57EED";
        options = "-a -o on -S on -T permissive -W 0,75 -n never,q -s (S/../.././02|L/../../7/04)";
      }
    ];
  };

  system.activationScripts.installerCustom = ''
    mkdir -p /shares/public
    mkdir -p /volumes/{parity,data1,data2,data3,data4,storage,cache}
    mkdir -p /var/snapraid
  '';
}
