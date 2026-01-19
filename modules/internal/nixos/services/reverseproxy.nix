{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz.roles.serviceHost;
in
{
  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;

      environmentFile = cfg.reverseProxySecretsFile;

      settings = {
        apps.tls.automation.policies = [
          {
            issuers = [
              {
                module = "acme";
                challenges.dns.provider = {
                  name = "cloudflare";
                  api_token = "{env.CLOUDFLARE_API_TOKEN}";
                };
              }
            ];
          }
        ];
      };
    };
  };
}
