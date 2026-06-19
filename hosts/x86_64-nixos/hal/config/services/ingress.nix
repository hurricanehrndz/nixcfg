{
  self,
  config,
  lib,
  isBootstrap ? false,
  ...
}:
{
  age.secrets = lib.mkIf (!isBootstrap) {
    "ingress.env".file = "${self}/secrets/services/ingress/env.age";
  };

  hrndz.services.ingress = lib.mkIf (!isBootstrap) {
    enable = true;
    environmentFiles = [
      config.age.secrets."ingress.env".path
    ];

    # Omada serves HTTPS with a self-signed cert on :8043, so upstream TLS
    # verification has to be skipped.
    settings.serversTransport.insecureSkipVerify = true;

    extraConfig.traefik-dashboard = {
      http.routers.traefik = {
        rule = "Host(`${config.networking.hostName}.${config.networking.domain}`) && PathPrefix(`/traefik`)";
        entryPoints = [ "websecure" ];
        service = "api@internal";
        tls.certResolver = "default";
      };
    };
  };
}
