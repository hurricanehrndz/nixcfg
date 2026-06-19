{ ... }:
{
  # SMART monitoring for the boot NVMe. Mirrors the DeepThought smartd setup:
  # short self-test nightly at 02:00, long self-test Sundays at 04:00.
  services.smartd = {
    enable = true;
    # Headless host; alerting goes through scrutiny -> Telegram instead.
    # Disabling wall also drops smartd-notify.sh + envsubst from the closure.
    notifications.wall.enable = false;
    devices = [
      {
        # The disko `main` disk (Samsung EVO NVMe, /dev/nvme0n1). Switch to a
        # /dev/disk/by-id/nvme-* path if you want it pinned to this exact drive.
        device = "/dev/nvme0n1";
        # Same flags DeepThought uses for its NVMe. -W 0,75 raises the temp
        # warning to 75C (NVMe runs hotter than SATA SSDs); the -o/-S ATA-only
        # directives are no-ops on NVMe and tolerated via -T permissive.
        options = "-a -o on -S on -T permissive -W 0,75 -n never,q -s (S/../.././02|L/../../7/04)";
      }
    ];
  };
}
