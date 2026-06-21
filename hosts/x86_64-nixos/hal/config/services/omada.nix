{
  config,
  lib,
  isBootstrap ? false,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  systemd.services."podman-omada-controller".serviceConfig.LimitNOFILE = "4096:8192";
  virtualisation.oci-containers.containers = {
    omada-controller = {
      image = "docker.io/mbentley/omada-controller:5.15";
      environment = {
        TZ = "America/Edmonton";
      };
      ports = [
        "8043:8043" # management UI
        "127.0.0.1:8843:8843" # captive portal
        "29810:29810/udp"
        "29811-29816:29811-29816"
      ];
      volumes = [
        "omada-data:/opt/tplink/EAPController/data"
        "omada-logs:/opt/tplink/EAPController/logs"
      ];
      extraOptions = [
        "--ulimit=nofile=4096:8192"
      ];
    };
  };

  # Reverse proxy for the Omada UI. Replaces the old services.traefikProxy config.
  hrndz.services.ingress.sites.omada = mkIf (!isBootstrap && config.hrndz.services.ingress.enable) {
    host = "omada.${config.networking.domain}";
    proxy = "https://127.0.0.1:8043";
  };

  # Omada device discovery/adoption ports (the ingress module opens 80/443).
  networking.firewall.allowedTCPPorts = [ 8043 ];
  networking.firewall.allowedUDPPorts = [ 29810 ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 29811;
      to = 29816;
    }
  ];

}
