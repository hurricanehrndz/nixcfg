{
  self,
  config,
  ...
}:
{
  # homarr
  age.secrets = {
    "homarr.env".file = "${self}/secrets/services/homarr/env.age";
  };
  virtualisation.oci-containers.containers = {
    homarr = {
      image = "ghcr.io/homarr-labs/homarr:latest";
      ports = [
        "127.0.0.1:7575:7575"
      ];
      volumes = [
        "/opt/homarr:/appdata"
      ];
      environmentFiles = [
        config.age.secrets."homarr.env".path
      ];
    };
  };
  services.traefikProxy.dynamicConfigOptions."homarr" = {
    enable = true;
    value = {
      http.services = {
        "homarr" = {
          loadbalancer.servers = [
            { url = "http://localhost:7575/"; }
          ];
        };
      };
      http.routers = {
        "homarr" = with config.networking; {
          rule = "Host(`${hostName}.${domain}`)";
          entryPoints = [
            "websecure"
          ];
          service = "homarr";
          tls.certResolver = "dnsResolver";
          priority = 1;
        };
      };
    };
  };
}
