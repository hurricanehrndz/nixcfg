{
  config,
  lib,
  isBootstrap ? false,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.services.scrutiny;
in
{
  # smart monitoring reporting
  services.scrutiny = {
    enable = true;
    settings.web.listen.port = 1080;
    settings.web.listen.basepath = "/storage";
    collector = {
      enable = true;
      schedule = "daily";
    };
  };

  hrndz.services.ingress.sites = mkIf (!isBootstrap && config.hrndz.services.ingress.enable) {
    "scrutiny" = {
      proxy = ":${toString cfg.settings.web.listen.port}";
      path = cfg.settings.web.listen.basepath;
    };
  };
}
