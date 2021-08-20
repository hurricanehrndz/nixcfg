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
    home = {
      keyboard.layout = "us";
      language.base = "en_US.utf8";
    };
    # Install home-manager manpages.
    manual.manpages.enable = true;

    # Install man output for any Nix packages.
    programs.man.enable = true;

    # Install cachix
    home.packages = with pkgs; [
      cachix
      coreutils
    ];

    hurricane.configs = {
      shell.enable = true;
      tmux.enable = true;
      nix.enable = true;
    };
  };
}
