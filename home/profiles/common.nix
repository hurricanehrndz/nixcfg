{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.common;
in
{
  options.hurricane.profiles.common = {
    enable = mkEnableOption "common configuration";
  };

  config = mkIf cfg.enable {
    keyboard.layout = "us";
    language.base = "en_US.utf8";
    # Install home-manager manpages.
    manual.manpages.enable = true;

    # Install man output for any Nix packages.
    programs.man.enable = true;

    hurricane.configs = {
      shell.enable = true;
      # zsh plugin manager
      sheldon.enable = true;
    };
  };
}
