{
  self,
  config,
  lib,
  isBootstrap ? false,
  ...
}:
{
  imports = [
    ./scrutiny.nix
  ];

  hrndz.services.autoUpdateContainers.enable = true;

  age.secrets = lib.mkIf (!isBootstrap) {
    "ingress.env".file = "${self}/secrets/services/ingress/env.age";
    "homarr.env".file = "${self}/secrets/services/homarr/env.age";
    "sAPIKey".file = "${self}/secrets/services/media-app-stack/skey.age";
    "rAPIKey".file = "${self}/secrets/services/media-app-stack/rkey.age";
  };

  hrndz.services.ingress = lib.mkIf (!isBootstrap) {
    enable = true;
    environmentFiles = [
      config.age.secrets."ingress.env".path
    ];
    extraConfig.traefik-dashboard = {
      http.routers.traefik = {
        rule = "Host(`${config.networking.hostName}.${config.networking.domain}`) && PathPrefix(`/traefik`)";
        entryPoints = [ "websecure" ];
        service = "api@internal";
        tls.certResolver = "default";
      };
    };
  };

  hrndz.services.homarr = lib.mkIf (!isBootstrap) {
    enable = true;
    environmentFiles = [
      config.age.secrets."homarr.env".path
    ];
  };

  hrndz.services.dashdot = lib.mkIf (!isBootstrap) {
    enable = true;
    fqdn = "deepdash.${config.networking.domain}";
  };

  hrndz.services.mediaAppStack = lib.mkIf (!isBootstrap) {
    enable = true;
    sAPIKey = config.age.secrets."sAPIKey".path;
    rAPIKey = config.age.secrets."rAPIKey".path;
  };

  hrndz.services.calibreWebAutomated = lib.mkIf (!isBootstrap) {
    enable = true;
  };
}
