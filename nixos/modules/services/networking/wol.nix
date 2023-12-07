{
  config,
  lib,
  pkgs,
  options,
  ...
}:
with lib; let
  cfg = config.services.WakeOnLan;
in {
  options.services.WakeOnLan = {
    enable = mkEnableOption "Enable wake-on-lan";

    macAddress = mkOption {
      type = types.str;
      description = ''
        Ethernet mac address
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.network = {
      links = {
        "50-wired" = {
          matchConfig.MACAddress = "${cfg.macAddress}";
          linkConfig = {
            NamePolicy = "kernel database onboard slot path";
            MACAddressPolicy = "persistent";
            WakeOnLan = "magic";
          };
        };
      };
    };
    environment.systemPackages = with pkgs; [
      ethtool
    ];
  };
}
