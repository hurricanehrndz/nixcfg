{
  pkgs,
  lib,
  config,
  ...
}: let
  mkFileSystems = let
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
    diskLabelList: lib.fold (attrset: acc: lib.recursiveUpdate acc attrset) {} (map mkFileSystemEntry diskLabelList);
in {
  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      parted
      smartmontools
    ];
  };

  fileSystems =
    (mkFileSystems ["parity" "data1" "data2" "data3" "data4"])
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
    defaults.monitored = "-a -o on -S on -T permissive -R 5! -W 0,46 -n never,q -s (S/../.././02|L/../../7/04)";
    devices = [
      {
        device = "/dev/disk/by-id/ata-ADATA_SU800_2I5020042202";
      }
      {
        device = "/dev/disk/by-id/ata-WDC_WD120EFBX-68B0EN0_5QKDEPLB";
      }
      {
        device = "/dev/disk/by-id/ata-ST12000VN0008-2PH103_ZTN18K65";
        options = "-a -o on -S on -T permissive -v 1,raw48:54 -v 7,raw48:54 -R 5! -W 0,46 -n never,q -s (S/../.././02|L/../../7/04)";
      }
      {
        device = "/dev/disk/by-id/ata-ST12000VN0008-2PH103_ZL2PSACH";
        options = "-a -o on -S on -T permissive -v 1,raw48:54 -v 7,raw48:54 -R 5! -W 0,46 -n never,q -s (S/../.././02|L/../../7/04)";
      }
      {
        device = "/dev/nvme0n1";
        options = "-a -o on -S on -T permissive -W 0,75 -n never,q -s (S/../.././02|L/../../7/04)";
      }
    ];
  };

  # smart monitoring reporting
  services.scrutiny = {
    enable = true;
    basepath = "/storage";
    settings.web.listen.port = 1080;
    settings.web.listen.host = "127.0.0.1";
    influxdb.enable = true;
    collector = {
      enable = true;
      settings = {
        host.id = "deepthought";
        api.endpoint = "http://localhost:1080/storage";
      };
    };

  };
  services.traefikProxy.dynamicConfigOptions."scrutiny" = {
    enable = true;
    value = {
      http.services = {
        "scrutiny" = {
          loadbalancer.servers = [
            {url = "http://localhost:1080/";}
          ];
        };
      };
      http.routers = {
        "scrutiny" = with config.networking; {
          rule = "Host(`${hostName}.${domain}`) && PathPrefix(`/storage`)";
          entryPoints = [
            "websecure"
          ];
          service = "scrutiny";
          tls.certResolver = "dnsResolver";
        };
      };
    };
  };

  system.activationScripts.installerCustom = ''
    mkdir -p /shares/public
    mkdir -p /volumes/{parity,data1,data2,data3,data4,storage,cache}
    mkdir -p /var/snapraid
  '';
}
