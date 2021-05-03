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
    xdg.configFile."nix/nix.conf".text =
      let
        nixConf = import ./conf.nix;
        substituters = [ "https://cache.nixos.org" ] ++ nixConf.binaryCaches;
        trustedPublicKeys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ] ++ nixConf.binaryCachePublicKeys;
      in
      ''
        substituters = ${builtins.concatStringsSep " " substituters}
        trusted-public-keys = ${builtins.concatStringsSep " " trustedPublicKeys}
        sandbox = false
        experimental-features = nix-command flakes ca-references
      '';
  };
}
