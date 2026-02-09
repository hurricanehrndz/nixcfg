{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  cfg = config.hrndz.nixos.networkd-dhcp;
in
{
  options.hrndz.nixos.networkd-dhcp = {
    enable = mkEnableOption "Enable networkd DHCP" // {
      default = false;
    };
  };
  config = mkIf cfg.enable {
    networking.useDHCP = false;
    networking.useNetworkd = true;
    systemd.network = {
      enable = true;
      networks = {
        "99-en-dhcp" = {
          matchConfig.Name = "en*";
          networkConfig.DHCP = "yes";
        };
      };
    };
  };
}
