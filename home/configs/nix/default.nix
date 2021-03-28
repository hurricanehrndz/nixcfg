{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.nix;
in
{
  options.hurricane = {
    configs.nix.enable = mkEnableOption "enable custom nix conf";
  };

  config = mkIf cfg.enable {
     xdg.configFile."nix/nix.conf".source = ./nix.conf;
  };
}
