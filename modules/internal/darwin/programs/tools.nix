{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.tui.enable {
    environment.systemPackages = with pkgs; [
      # commandline tool for battery, volume, wifi
      m-cli
      ncurses
    ];
  };
}
