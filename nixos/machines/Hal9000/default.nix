{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
        flags = ["--all"];
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

  services.traefikProxy.dynamicConfigOptions."omada" = {
    enable = true;
    value = {
      http.services = {
        "omada" = {
          loadbalancer.servers = [
            {url = "https://localhost:8043/";}
          ];
        };
      };
      http.routers = {
        "omada" = {
          rule = "Host(`omada.${config.networking.domain}`)";
          entryPoints = [
            "websecure"
          ];
          service = "omada";
          tls.certResolver = "dnsResolver";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [8043];
  networking.firewall.allowedUDPPorts = [29810];
  networking.firewall. allowedTCPPortRanges = [
    {
      from = 29811;
      to = 29816;
    }
  ];

  system.stateVersion = "25.05";
}
# vim: set et sw=2 :

