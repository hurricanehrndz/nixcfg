{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        # Current Lucy host reports a single Micron 1100 SATA SSD as /dev/sda.
        # Keep mkDefault so the device can be overridden during installation if needed.
        device = lib.mkDefault "/dev/sda";
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

            nixos = {
              size = "100%";
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
