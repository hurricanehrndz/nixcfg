{
  config,
  lib,
  isBootstrap ? false,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.hrndz.services.calibreWebAutomated;
in
{
  options.hrndz.services.calibreWebAutomated = {
    enable = mkEnableOption "Calibre-Web-Automated";

    port = mkOption {
      type = types.port;
      default = 8083;
    };

    host = mkOption {
      type = types.str;
      default = "books.${config.networking.domain}";
    };
  };

  config = mkIf (cfg.enable && !isBootstrap) {
    virtualisation.oci-containers.containers.calibre-web-automated = {
      image = "crocodilestick/calibre-web-automated:latest";
      ports = [
        "127.0.0.1:${toString cfg.port}:8083"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "America/Edmonton";
        CWA_PORT_OVERRIDE = "8083";
        NETWORK_SHARE_MODE = "false";
      };
      volumes = [
        "/var/lib/calibre-web-automated/config:/config"
        "/volumes/books/ebooks/ingest:/cwa-book-ingest"
        "/volumes/books/ebooks/library:/calibre-library"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/calibre-web-automated 0755 hurricane users - -"
      "d /var/lib/calibre-web-automated/config 0755 hurricane users - -"
      "d /var/lib/calibre-web-automated/ingest 0775 hurricane users - -"
    ];

    hrndz.services.ingress.sites.calibre-web-automated = mkIf config.hrndz.services.ingress.enable {
      host = cfg.host;
      proxy = ":${toString cfg.port}";
    };
  };
}
