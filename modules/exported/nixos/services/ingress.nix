{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hrndz.services.ingress;
  settingsFormat = pkgs.formats.yaml { };

  # --- HELPER: Generate Site Configs ---
  mkSiteConfig =
    name: siteCfg:
    let
      # 1. Determine the Host
      # If not set, default to the machine's FQDN
      host =
        if siteCfg.host != null then
          siteCfg.host
        else
          "${config.networking.hostName}.${config.networking.domain}";

      # 2. Determine Upstream
      upstream =
        if hasPrefix ":" siteCfg.proxy then "http://127.0.0.1${siteCfg.proxy}" else siteCfg.proxy;

      # 3. Generate the Rule
      # Logic:
      #   - If 'rule' is explicitly set, use it (Escape Hatch).
      #   - If 'path' is set, use Host(host) && PathPrefix(path).
      #   - Otherwise, use Host(host).
      finalRule =
        if siteCfg.rule != null then
          siteCfg.rule
        else if siteCfg.path != null then
          "Host(`${host}`) && PathPrefix(`${siteCfg.path}`)"
        else
          "Host(`${host}`)";

      # Sanitize name for filenames (replace special chars)
      safeName = replaceStrings [ "." "/" "*" ] [ "-" "-" "-" ] name;

    in
    {
      name = "${safeName}.yml";
      path = settingsFormat.generate "${safeName}.yml" {
        http = {
          routers."${safeName}" = {
            rule = finalRule;
            service = "${safeName}";
            entryPoints = [ "websecure" ];
            tls.certResolver = "default";
            middlewares = siteCfg.middlewares;
          };
          services."${safeName}".loadBalancer.servers = [ { url = upstream; } ];
        };
      };
    };

  # --- HELPER: Process Extra Raw Configs ---
  mkExtraConfig = name: value: {
    name = "extra-${name}.yml";
    path = settingsFormat.generate "${name}.yml" value;
  };

  # --- BUILD PHASE ---
  siteFiles = mapAttrsToList mkSiteConfig (filterAttrs (_: s: s.enable) cfg.sites);
  extraFiles = mapAttrsToList mkExtraConfig cfg.extraConfig;

  # Create the immutable directory in /nix/store
  ingressConfDerivation = pkgs.linkFarm "ingress-conf.d" (siteFiles ++ extraFiles);

in
{
  options.hrndz.services.ingress = {
    enable = mkEnableOption "Traefik-based Ingress Controller";

    environmentFiles = mkOption {
      type = with types; nullOr (listOf path);
      default = null;
      description = "Paths to EnvironmentFiles with secrets (e.g. CF_DNS_API_TOKEN).";
    };

    settings = mkOption {
      description = "Static Traefik configuration (merges with defaults).";
      default = { };
      type = settingsFormat.type;
    };

    sites = mkOption {
      description = "Simplified site definitions.";
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };

            proxy = mkOption {
              type = types.str;
              description = "Upstream URL or port (e.g. :3000).";
            };

            host = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Hostname to match. Defaults to system FQDN.";
            };

            path = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Path prefix (e.g. '/api'). Automatically added to Host rule.";
            };

            rule = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Raw Traefik rule. Overrides host/path logic if set.";
            };

            middlewares = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of middleware names.";
            };
          };
        }
      );
    };

    extraConfig = mkOption {
      description = "Raw Traefik dynamic configuration.";
      default = { };
      type = types.attrsOf settingsFormat.type;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.traefik = {
      enable = true;
      environmentFiles = optionals (cfg.environmentFiles != null) cfg.environmentFiles;

      staticConfigOptions = recursiveUpdate {
        log.level = "INFO";
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
          };
          # because api.insecure = true
          traefik.address = "127.0.0.1:48080";
        };
        certificatesResolvers.default.acme = {
          email = "postmaster@${config.networking.domain}";
          storage = "${config.services.traefik.dataDir}/acme.json";
          dnsChallenge = {
            provider = "cloudflare";
            resolvers = [
              "1.1.1.1:53"
              "8.8.8.8:53"
            ];
          };
        };
        api = {
          basePath = "/traefik";
          insecure = true;
          dashboard = true;
        };

        # Point to Immutable Store Path
        providers.file = {
          directory = "${ingressConfDerivation}";
        };
      } cfg.settings;
    };
  };
}
