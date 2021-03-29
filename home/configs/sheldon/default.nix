{ config, lib, ... }:

with lib;
let
  cfg = config.hurricane.configs.sheldon;
in
{
  options.hurricane.configs.sheldon.enable = mkEnableOption "sheldon config";

  config = mkIf cfg.enable {
    programs.sheldon = {
      enable = true;
    };
    xdg.configFile."sheldon/plugins.toml".source = ./plugins.toml;
  };
}