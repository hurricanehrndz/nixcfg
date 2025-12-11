{
  self',
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    home.packages =
      with pkgs;
      with self'.packages;
      [
        sops
        age
        strongbox
        strongbox-init
      ];
  };
}
