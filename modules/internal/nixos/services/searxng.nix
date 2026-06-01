{
  config,
  lib,
  pkgs,
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
  cfg = config.hrndz.services.searxng;
in
{
  options.hrndz.services.searxng = {
    enable = mkEnableOption "SearXNG metasearch engine" // {
      default = false;
    };

    port = mkOption {
      type = types.port;
      default = 8888;
    };

    host = mkOption {
      type = types.str;
      default = "search.${config.networking.domain}";
    };

    environmentFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "EnvironmentFile providing SEARXNG_SECRET (referenced as $SEARXNG_SECRET).";
    };
  };

  config = mkIf (cfg.enable && !isBootstrap) {
    services.searx = {
      enable = true;
      package = pkgs.searxng;
      redisCreateLocally = true;
      inherit (cfg) environmentFile;
      settings = {
        server = {
          port = cfg.port;
          bind_address = "127.0.0.1";
          secret_key = "$SEARXNG_SECRET";
          base_url = "https://${cfg.host}/";
        };
        ui.static_use_hash = true;
        search.formats = [
          "html"
          "json"
        ];
      };
    };

    hrndz.services.ingress.sites = mkIf config.hrndz.services.ingress.enable {
      "searxng" = {
        host = cfg.host;
        proxy = ":${toString cfg.port}";
      };
    };
  };
}
