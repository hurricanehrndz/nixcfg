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
  #
  # scrutiny runs as a systemd DynamicUser, and its pre-start (which reads
  # this secret to template the config) runs as that user. The default
  # root-only agenix secret is therefore unreadable, so expose it through a
  # dedicated group the service joins.
  users.groups.scrutiny-secrets = { };

  age.secrets = mkIf (!isBootstrap) {
    "scrutiny-notify-url" = {
      file = "${self}/secrets/services/scrutiny/notify-url.age";
      group = "scrutiny-secrets";
      mode = "0440";
    };
  };

  systemd.services.scrutiny.serviceConfig.SupplementaryGroups = [ "scrutiny-secrets" ];

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
      settings.host.id = "DeepThought";
    };
  };

  hrndz.services.ingress.sites = mkIf (!isBootstrap && config.hrndz.services.ingress.enable) {
    "scrutiny" = {
      proxy = ":${toString cfg.settings.web.listen.port}";
      path = cfg.settings.web.listen.basepath;
    };
  };
}
