{ ... }:
{
  # Hourly snapshots of service state, books, vaults and home, sent to the backup SSD.
  # Named "btrbk" so /etc/btrbk/btrbk.conf is btrbk's default config path and
  # `sudo btrbk snapshot` (run by `just switch`) needs no -c flag.
  services.btrbk.instances.btrbk = {
    onCalendar = "hourly";
    settings = {
      timestamp_format = "long";
      snapshot_preserve_min = "2d";
      snapshot_preserve = "24h 7d 4w";
      target_preserve_min = "no";
      # btrbk only sends snapshots the target policy keeps; 24h makes every
      # hourly snapshot reach the SSD, not just the first of each day.
      target_preserve = "24h 14d 8w 6m";

      volume."/" = {
        snapshot_dir = ".snapshots";
        target = "/backups/DeepThought";
        subvolume = {
          "var" = { };
          "volumes/books" = { };
          "volumes/vaults" = { };
        };
      };
      volume."/home" = {
        snapshot_dir = ".snapshots";
        target = "/backups/DeepThought";
        subvolume."." = { };
      };
    };
  };
}
