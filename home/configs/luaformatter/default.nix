{ config, lib, pkgs, ... }:

with lib;
let cfg = config.hurricane.configs.luaformatter;
in {
  options.hurricane.configs = {
    luaformatter.enable = mkEnableOption "luaformt";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs;
      [ ] ++ optional stdenv.isLinux [ luaformatter ];

    xdg.configFile."luaformatter/config.yaml".source = ./luaformat.yml;
  };
}
