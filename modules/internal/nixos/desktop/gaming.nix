{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.hrndz.desktop.gaming;
in
{
  options.hrndz.desktop.gaming = {
    enable = mkEnableOption "Steam with Proton, gamemode, gamescope and MangoHud";
  };

  config = mkIf cfg.enable {
    # Native rather than Flatpak Steam: the NixOS module brings controller udev
    # rules and 32-bit graphics, and libraries outside $HOME need no overrides.
    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      protontricks.enable = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

    users.users.${config.system.primaryUser}.extraGroups = [ "gamemode" ];

    environment.systemPackages = [ pkgs.mangohud ];
  };
}
