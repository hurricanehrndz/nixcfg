{ self, config, ... }:

{
  age.secrets = {
    "traefik.env".file = "${self}/secrets/services/traefik/env.age";
  };

  services.traefikProxy = {
    enable = true;
    environmentFile = config.age.secrets."traefik.env".path;
  };
}

