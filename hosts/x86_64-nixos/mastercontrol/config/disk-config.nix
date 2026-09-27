{ ... }:
let
  cow = [
    "compress=zstd"
    "noatime"
  ];
  nocow = [ "noatime" ];
in
{
  disko.devices = {
    disk = {
      # WD_BLACK SN850 2TB, CPU-attached Gen4: OS, home and games.
      main = {
        device = "/dev/disk/by-id/nvme-WDS200T1X0E-00AFY0_213737800213";
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
                    mountOptions = cow;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = cow;
                  };
                  "@var" = {
                    mountpoint = "/var";
                    mountOptions = cow;
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = cow;
                  };
                  # Re-downloadable, so kept out of btrbk.
                  "@games" = {
                    mountpoint = "/volumes/games";
                    mountOptions = cow;
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = cow;
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

      # ADATA SX8200 Pro 1TB, behind the chipset: VM and container storage, kept
      # off the desktop's disk. NOCOW via tmpfiles below (except read-only
      # portables). Subvolumes are named by their real paths; this filesystem
      # has no @ to nest them under.
      vm = {
        device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2J4520094328";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            vm = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "var/lib/libvirt/images" = {
                    mountpoint = "/var/lib/libvirt/images";
                    mountOptions = nocow;
                  };
                  "var/lib/containers" = {
                    mountpoint = "/var/lib/containers";
                    mountOptions = nocow;
                  };
                  "var/lib/machines" = {
                    mountpoint = "/var/lib/machines";
                    mountOptions = nocow;
                  };
                  "var/lib/portables" = {
                    mountpoint = "/var/lib/portables";
                    mountOptions = nocow;
                  };
                  "home/hurricane/.local/share/containers" = {
                    mountpoint = "/home/hurricane/.local/share/containers";
                    mountOptions = nocow;
                  };
                };
              };
            };
          };
        };
      };

      # Crucial MX500 1TB: btrbk target. nofail so a dead backup disk can't
      # block boot; btrbk's target dir only exists on it, so btrbk fails loudly
      # instead of writing to / when it is missing.
      backup = {
        device = "/dev/disk/by-id/ata-CT1000MX500SSD1_2038E4B13653";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            backup = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "backup"
                ];
                mountpoint = "/backups";
                mountOptions = cow ++ [ "nofail" ];
              };
            };
          };
        };
      };
    };
  };

  # Top level of the root fs, mounted on demand for whole-subvolume rollbacks.
  fileSystems."/.btrfs" = {
    device = "/dev/disk/by-partlabel/disk-main-nixos";
    fsType = "btrfs";
    options = [
      "subvolid=5"
      "noatime"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=5min"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /volumes/games 0755 hurricane users -"
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
