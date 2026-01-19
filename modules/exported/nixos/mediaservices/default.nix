{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    ;
  cfg = config.hrndz.services.mediaservices;
in
{
  options.hrndz.services.mediaservices = with types; {
    enable = mkEnableOption "Caddy reverse proxy for media services";

    defaultHostname = mkOption {
      type = str;
      description = "Default hostname for media services";
    };

    domain = mkOption {
      type = str;
      description = "Domain for media services";
    };

    services = mkOption {
      type = listOf (submodule {
        options = {
          name = mkOption { type = str; };
          package = mkOption {
            type = nullOr package;
            default = null;
          };
          port = mkOption { type = str; };
          groups = mkOption {
            type = nullOr str;
            default = null;
          };
          extraGroups = mkOption {
            type = listOf str;
            default = [ ];
          };
          altHostName = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
      default = [ ];
      example = [
        {
          name = "tautulli";
          port = "8181";
        }
      ];
    };
  };

  config = mkIf cfg.enable (
    let
      enableService =
        serviceOptions:
        let
          serviceName = serviceOptions.name;
          servicePackage = serviceOptions.package;
        in
        {
          services."${serviceName}" = {
            enable = true;
          }
          // (
            if servicePackage != null then
              {
                package = servicePackage;
              }
            else
              { }
          )
          // (
            if serviceOptions.groups != null then
              {
                group = serviceOptions.groups;
              }
            else
              { }
          );
          users.users.${serviceName}.extraGroups = serviceOptions.extraGroups;
          systemd.services.${serviceName}.serviceConfig.UMask = "0002";
        };

      makeRoute =
        serviceOptions:
        let
          serviceName = serviceOptions.name;
          servicePort = serviceOptions.port;
          hostMatch =
            if serviceOptions.altHostName != null then
              "${serviceOptions.altHostName}.${cfg.domain}"
            else
              "${cfg.defaultHostname}.${cfg.domain}";
          pathMatch = if serviceOptions.altHostName != null then "/" else "/${serviceName}*";
        in
        {
          match = [
            {
              host = [ hostMatch ];
              path = [ pathMatch ];
            }
          ];
          handle = [
            {
              handler = "reverse_proxy";
              upstreams = [
                { dial = "localhost:${servicePort}"; }
              ];
            }
          ];
        };

      serviceConfigs = map enableService cfg.services;
      routes = map makeRoute cfg.services;
    in
    lib.fold (attrset: acc: lib.recursiveUpdate acc attrset) {
      services.caddy.settings.apps.http.servers.mediaservices = {
        routes = routes;
      };
    } serviceConfigs
  );
}
