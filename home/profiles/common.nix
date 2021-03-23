{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.common;
in
{
  options.hurricane.profiles.common = {
    enable = mkEnableOption "common configurations";
  };

  config = mkIf cfg.enable {
    # Install home-manager manpages.
    manual.manpages.enable = true;

    hurricane.configs = {
      sheldon.enable = true;
    };
  };
}
