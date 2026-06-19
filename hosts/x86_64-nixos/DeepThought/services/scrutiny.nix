{
  self,
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
  # Telegram (Shoutrrr) alert URL. The module injects it into the rendered
  # config at runtime via `_secret` replacement, so it never lands in the
  # nix store.
  age.secrets = mkIf (!isBootstrap) {
    "scrutiny-notify-url".file = "${self}/secrets/services/scrutiny/notify-url.age";
  };

  # smart monitoring reporting
  services.scrutiny = {
    enable = true;
    settings.web.listen.port = 1080;
    settings.web.listen.basepath = "/storage";
    settings.notify.urls = mkIf (!isBootstrap) [
      { _secret = config.age.secrets."scrutiny-notify-url".path; }
    ];
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
