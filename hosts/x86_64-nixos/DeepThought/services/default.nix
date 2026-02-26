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
  };

  hrndz.services.ingress = lib.mkIf (!isBootstrap) {
    enable = true;
    environmentFiles = [
      config.age.secrets."ingress.env".path
    ];
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

  hrndz.services.mediaAppStack.enable = lib.mkIf (!isBootstrap) true;
}
