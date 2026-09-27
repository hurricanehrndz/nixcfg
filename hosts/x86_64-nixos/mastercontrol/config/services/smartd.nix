{ ... }:
let
  nvme = "-a -o on -S on -T permissive -W 0,75 -n never,q -s (S/../.././02|L/../../7/04)";
  sata = "-a -o on -S on -T permissive -R 5! -C 197+ -U 198+ -W 0,46,55 -n never,q -s (S/../.././02|L/../../7/04)";
in
{
  # Alerting is centralized through scrutiny -> Telegram on DeepThought.
  services.smartd = {
    enable = true;
    notifications.wall.enable = false;
    devices = [
      {
        device = "/dev/disk/by-id/nvme-WDS200T1X0E-00AFY0_213737800213";
        options = nvme;
      }
      {
        device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2J4520094328";
        options = nvme;
      }
      {
        device = "/dev/disk/by-id/ata-CT1000MX500SSD1_2038E4B13653";
        options = sata;
      }
    ];
  };
}
