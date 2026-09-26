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
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  # Container/VM storage, NOCOW via tmpfiles below (except read-only
                  # portables). Nested under @ at their real paths so they stay hidden
                  # beneath the @var/@home mounts and out of their snapshots.
                  "@/var/lib/libvirt/images" = {
                    mountpoint = "/var/lib/libvirt/images";
                    mountOptions = [
                      "noatime"
                    ];
                  };

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

                  "@/home/hurricane/.local/share/containers" = {
                    mountpoint = "/home/hurricane/.local/share/containers";
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

  systemd.tmpfiles.rules = [
    "d /home/hurricane/.local 0755 hurricane users -"
    "d /home/hurricane/.local/share 0755 hurricane users -"
    "d /home/hurricane/.local/share/containers 0700 hurricane users -"
    "h /home/hurricane/.local/share/containers - - - - +C"
    "d /var/lib/libvirt/images 0711 root root -"
    "h /var/lib/libvirt/images - - - - +C"
    "d /var/lib/containers 0755 root root -"
    "h /var/lib/containers - - - - +C"
    "d /var/lib/machines 0700 root root -"
    "h /var/lib/machines - - - - +C"
    "d /var/lib/portables 0700 root root -"
  ];
}
