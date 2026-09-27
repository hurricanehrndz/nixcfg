{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
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
            # Separate filesystem so a full root/var can't block logins.
            home = {
              size = "100G";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@snapshots" = {
                    mountpoint = "/home/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
            nixos = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
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
                    # Snapshotting /nix is generally redundant as it's reproducible
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@var" = {
                    mountpoint = "/var";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Container storage, NOCOW via tmpfiles below (except read-only
                  # portables). Nested under @ at their real paths so they stay hidden
                  # beneath the @var mount and out of its snapshots.
                  "@/var/lib/containers" = {
                    mountpoint = "/var/lib/containers";
                    mountOptions = [
                      "noatime"
                    ];
                  };
                  "@/var/lib/machines" = {
                    mountpoint = "/var/lib/machines";
                    mountOptions = [
                      "noatime"
                    ];
                  };
                  "@/var/lib/portables" = {
                    mountpoint = "/var/lib/portables";
                    mountOptions = [
                      "noatime"
                    ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@books" = {
                    mountpoint = "/volumes/books";
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
                        size = "16G";
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

  systemd.tmpfiles.rules = [
    "d /var/lib/containers 0755 root root -"
    "h /var/lib/containers - - - - +C"
    "d /var/lib/machines 0700 root root -"
    "h /var/lib/machines - - - - +C"
    "d /var/lib/portables 0700 root root -"
  ];
}
