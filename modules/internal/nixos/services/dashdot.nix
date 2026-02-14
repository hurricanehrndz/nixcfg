{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.hrndz.services.dashdot;
in
{
  options.hrndz.services.dashdot = {
    enable = mkEnableOption "Enable dashdot" // {
      default = false;
    };

    pageTitle = mkOption {
      type = types.str;
      description = "Dashdot Page Title";
      default = "dash.";
    };

    fqdn = mkOption {
      type = types.str;
      description = "FQDN";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dashdot = {
        image = "mauricenino/dashdot";
        privileged = true;
        ports = [
          "127.0.0.1:3001:3001"
        ];
        volumes = [
          "/:/mnt/host:ro"
          "/etc/os-release:/etc/os-release:ro"
          "/etc/hostname:/etc/hostname:ro"
        ];
        environment = {
          DASHDOT_SHOW_HOST = "false";
          DASHDOT_PAGE_TITLE = cfg.pageTitle;
          DASHDOT_ACCEPT_OOKLA_EULA = "true";
          DASHDOT_SPEED_TEST_INTERVAL = "480";
          DASHDOT_ENABLE_STORAGE_SPLIT_VIEW = "true";
          DASHDOT_ENABLE_CPU_TEMPS = "true";
        };
      };
    };
    hrndz.services.ingress.sites = mkIf config.hrndz.services.ingress.enable {
      "dashdot" = {
        host = cfg.fqdn;
        proxy = ":3001";
      };
    };
  };
}
