{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.desktop;
in {
  options.hurricane.profiles.desktop = { enable = mkEnableOption "desktop configuration"; };

  config = mkIf cfg.enable {
    hurricane.configs = {
      alacritty.enable = true;
    };
    home.packages = [
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "Hack" "FantasqueSansMono" "Meslo" "SourceCodePro" ]; })
    ];
  };
}
