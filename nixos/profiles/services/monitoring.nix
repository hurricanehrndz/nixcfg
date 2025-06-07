{config, ...}: {
  virtualisation.oci-containers.containers = {
    dashdot = {
      image = " mauricenino/dashdot";
      privileged = true;
      ports = [
        "127.0.0.1:3001:3001"
      ];
      volumes = [
        "/:/mnt/host:ro"
        "/etc/os-release:/etc/os-release:ro"
        "/etc/hostname:/etc/hostname:ro"
      ];
      environment = {
        DASHDOT_SHOW_HOST = "false";
        DASHDOT_PAGE_TITLE = "DeepThought";
        DASHDOT_ACCEPT_OOKLA_EULA = "true";
        DASHDOT_SPEED_TEST_INTERVAL = "480";
        DASHDOT_ENABLE_STORAGE_SPLIT_VIEW = "true";
        DASHDOT_ENABLE_CPU_TEMPS = "true";
      };
    };
  };
  services.traefikProxy.dynamicConfigOptions."dashdot" = {
    enable = true;
    value = {
      http.services = {
        "dashdot" = {
          loadbalancer.servers = [
            {url = "http://localhost:3001/";}
          ];
        };
      };
      http.routers = {
        "dashdot" = with config.networking; {
          rule = "Host(`deepdash.${domain}`)";
          entryPoints = [
            "websecure"
          ];
          service = "dashdot";
          tls.certResolver = "dnsResolver";
        };
      };
    };
  };
}
