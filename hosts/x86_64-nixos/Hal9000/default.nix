{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./users/hurricane.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "Hal9000";
  networking.domain = "hrndz.ca";

  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
  };

  virtualisation.oci-containers.containers = {
    omada-controller = {
      image = "docker.io/mbentley/omada-controller:latest";
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
  systemd.services."podman-omada-controller".serviceConfig.LimitNOFILE = "4096:8192";

  # Reverse proxy for the Omada UI. Replaces the old services.traefikProxy config.
  hrndz.services.ingress = {
    enable = true;
    # Omada serves HTTPS with a self-signed cert on :8043, so upstream TLS
    # verification has to be skipped.
    settings.serversTransport.insecureSkipVerify = true;
    sites.omada = {
      host = "omada.${config.networking.domain}";
      proxy = "https://127.0.0.1:8043";
    };
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

  system.primaryUser = "hurricane";
  system.stateVersion = "26.05";
}
# vim: set et sw=2 :
