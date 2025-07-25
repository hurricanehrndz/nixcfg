{ config, lib, pkgs, options, ... }:

with lib;
# Wrapper for nixpkgs traefik module with cook in personal defaults
# see: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-servers/traefik.nix
# Traekik: file and directory provider are mutually exclusive, wrapping to enable directory
let
  cfg = config.services.traefikProxy;
  dynamicConfDir = "${config.services.traefik.dataDir}/conf.d";
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.services.traefikProxy = with types; {
    enable = mkEnableOption "Traefik proxy";

    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Environment file (see <literal>systemd.exec(5)</literal>
        "EnvironmentFile=" section for the syntax) to define variables for
        Traefik. This option can be used to safely include secret keys into the
        Traefik configuration.
      '';
    };
    staticConfigOptions = mkOption {
      description = ''
        Static configuration for personal Traefik proxy.
      '';
      type = settingsFormat.type;
      example = {
        entryPoints.web.address = ":8080";
        entryPoints.http.address = ":80";
        api = { };
      };
      default = {
        log = {
          level = "DEBUG";
        };
        serversTransport.forwardingTimeouts.idleConnTimeout = "5s";
        serversTransport.insecureSkipVerify = true;
        api = {
          basePath = "/traefik";
          insecure = true;
          dashboard = true;
        };
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entrypoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure.address = ":443";
        };
        certificatesResolvers.dnsResolver.acme = {
          dnschallenge = {
            provider = "cloudflare";
            resolvers = [
              "1.1.1.1:53"
              "8.8.8.8:53"
            ];
          };
          # TRAEFIK_CERTIFICATESRESOLVERS_<NAME>_ACME_EMAIL:
          storage = "${config.services.traefik.dataDir}/acme.json";
        };
      };
    };
    dynamicConfigOptions = mkOption {
      description = ''
        Dynamic configurations for Traefik.
      '';
      type = with types; attrsOf (submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
          };
          value = mkOption {
            type = settingsFormat.type;
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d '${dynamicConfDir}' 0700 traefik traefik - -" ];
    services.traefik =
      let
        staticConfigFile = settingsFormat.generate "traefik-static.yml" (
          recursiveUpdate cfg.staticConfigOptions {
            providers.file.directory = "${dynamicConfDir}";
          }
        );
      in
      {
        enable = true;
        staticConfigFile = "${staticConfigFile}";
      };

    services.traefikProxy = {
      dynamicConfigOptions.defaultConfig = {
        enable = true;
        value = {
          http.middlewares = {
            add-permanent-slash = {
              redirectregex = {
                permanent = true;
                regex = "^(https?://[^/]+/[a-z0-9_]+)$";
                replacement = ''''${1}/'';
              };
            };
            strip-service-slug = {
              stripprefixregex.regex = "/[a-z0-9_]+";
            };
            our-slash = {
              chain.middlewares = [
                "add-permanent-slash"
                "strip-service-slug"
              ];
            };
          };
          http.routers = {
            # Route internal api
            traefik = with config.networking; {
              rule = "Host(`${hostName}.${domain}`) && PathPrefix(`/traefik`)";
              entryPoints = [
                "websecure"
              ];
              middlewares = [];
              service = "api@internal";
              tls.certResolver = "dnsResolver";
            };
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
    systemd.services.traefik =
      let
        dynamicConfigs_symlink_cmds =
          let
            buildConfigFile = key: configFile:
              let
                name = "${key}.yml";
                file = settingsFormat.generate name configFile.value;
              in
              "ln -sf ${file} ${dynamicConfDir}/${name}";
            buildConfigFiles = mapAttrsToList buildConfigFile;
          in
          pipe cfg.dynamicConfigOptions [
            (filterAttrs (_: conf: conf.enable))
            buildConfigFiles
          ];
      in
      {
        preStart = ''
          find ${dynamicConfDir} -type l -delete

        '' + (concatStringsSep "\n" dynamicConfigs_symlink_cmds);
      } // optionalAttrs (cfg.environmentFile != null) {
        serviceConfig.EnvironmentFile = [ cfg.environmentFile ];
      };
  };
}

