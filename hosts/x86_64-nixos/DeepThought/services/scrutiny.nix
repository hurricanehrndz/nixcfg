{
  lib,
  isBootstrap ? false,
  ...
}:
let
  inherit (lib) optionalAttrs;
in
{
  # smart monitoring reporting
  virtualisation.oci-containers.containers = {
    scrutiny = {
      image = "ghcr.io/analogj/scrutiny:master-omnibus";
      ports = [
        "127.0.0.1:1080:1080"
      ];
      environment = {
        COLLECTOR_API_ENDPOINT = "http://localhost:1080/storage";
        COLLECTOR_CRON_SCHEDULE = "0 0 * * *";
        DEBUG = "true";
        SCRUTINY_LOG_FILE = "/tmp/web.log";
      };
      volumes = [
        "/var/lib/scrutiny/config:/opt/scrutiny/config"
        "/var/lib/scrutiny/influxdb:/opt/scrutiny/influxdb"
        "/run/udev:/run/udev:ro"
      ];
      extraOptions = [
        "--pull=newer"
        "--cap-add=SYS_RAWIO"
        "--device=/dev/sda"
        "--device=/dev/sdb"
        "--device=/dev/sdc"
        "--device=/dev/sdd"
        "--device=/dev/sde"
        "--device=/dev/sdf"
        "--device=/dev/sdg"
        "--device=/dev/nvme0n1"
      ];
    };
  };
}
// optionalAttrs (!isBootstrap) {
  hrndz.services.ingress.sites."scrutiny" = {
    proxy = ":1080";
    path = "/storage";
  };
}
