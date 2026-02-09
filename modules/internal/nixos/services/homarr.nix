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
    optionals
    types
    ;
  cfg = config.hrndz.services.homarr;
in
{
  options.hrndz.services.homarr = {
    enable = mkEnableOption "Enable homarr" // {
      default = false;
    };

    environmentFiles = mkOption {
      type = with types; nullOr (listOf path);
      description = "Must contain the secrets encryption key";
      default = null;
    };
  };

  config = mkIf (cfg.enable && !isBootstrap) {
    virtualisation.oci-containers.containers = {
      homarr = {
        image = "ghcr.io/homarr-labs/homarr:latest";
        ports = [
          "127.0.0.1:7575:7575"
        ];
        volumes = [
          "/var/lib/homarr:/appdata"
        ];
        environmentFiles = optionals (cfg.environmentFiles != null) cfg.environmentFiles;
      };
    };
    hrndz.services.ingress.sites."homarr" = {
      proxy = ":7575";
    };
  };
}
