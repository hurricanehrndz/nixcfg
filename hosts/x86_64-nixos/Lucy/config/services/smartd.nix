{ ... }:
{
  # SMART monitoring for the boot SSD. Mirrors the DeepThought/hal smartd
  # setup: short self-test nightly at 02:00, long self-test Sundays at 04:00.
  services.smartd = {
    enable = true;
    # Alerting is centralized through scrutiny -> Telegram on DeepThought, so
    # local wall messages are redundant. Disabling wall also drops
    # smartd-notify.sh + envsubst from the closure.
    notifications.wall.enable = false;
    devices = [
      {
        # The disko `main` disk (Micron 1100 SATA SSD, /dev/sda). Switch to a
        # /dev/disk/by-id/ata-* path if you want it pinned to this exact drive.
        device = "/dev/sda";
        # SATA-SSD flags matching DeepThought's SSDs: -C 197+/-U 198+ watch
        # reallocated/pending sectors, -W 0,46,55 sets the temp warning band.
        options = "-a -o on -S on -T permissive -R 5! -C 197+ -U 198+ -W 0,46,55 -n never,q -s (S/../.././02|L/../../7/04)";
      }
    ];
  };
}
