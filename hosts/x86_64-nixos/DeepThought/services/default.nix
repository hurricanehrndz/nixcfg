{
  self,
  config,
  lib,
  isBootstrap ? false,
  ...
}:
let
  inherit (lib) optionalAttrs;
in
{
  imports = [
    ./scrutiny.nix
  ];
}
// optionalAttrs (!isBootstrap) {
  age.secrets = {
    "ingress.env".file = "${self}/secrets/services/ingress/env.age";
    "homarr.env".file = "${self}/secrets/services/homarr/env.age";
  };

  hrndz.services.ingress = {
    enable = true;
    environmentFiles = [
      config.age.secrets."ingress.env".path
    ];
  };

  hrndz.services.homarr = {
    enable = true;
    environmentFiles = [
      config.age.secrets."homarr.env".path
    ];
  };

  hrndz.services.dashdot = {
    enable = true;
    fqdn = "deepdash.${config.networking.domain}";
  };

  hrndz.services.mediaAppStack.enable = true;
}
