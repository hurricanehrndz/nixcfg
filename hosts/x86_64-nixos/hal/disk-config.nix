{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        # Samsung EVO NVMe SSD. mkDefault so it can be overridden at install time.
        device = lib.mkDefault "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "5G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "umask=0077"
                ];
              };
            };

            # Capped well below the 500G drive size: the ~65G left unpartitioned
            # is host-side over-provisioning, giving the SSD controller extra spare
            # blocks for wear-leveling and lower write amplification over its life.
            nixos = {
              size = "400G";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                postMountHook = ''
                  if mountpoint -q /mnt/var; then
                    chattr +C /mnt/var || true
                  fi
                '';
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # COW disabled (postMountHook) to avoid write amplification on
                  # Omada's embedded MongoDB under /var/lib/containers.
                  "@var" = {
                    mountpoint = "/var";
                    mountOptions = [
                      "noatime"
                    ];
                  };

                  "@srv" = {
                    mountpoint = "/srv";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  "@swap" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile = {
                        priority = -2;
                        size = "8G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
