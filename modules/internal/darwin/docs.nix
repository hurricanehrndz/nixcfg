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
  config = mkIf cfg.roles.terminalDeveloper.enable {
    documentation.enable = true;
    environment.systemPackages = [
      pkgs.lixPackageSets.stable.lix.doc
    ];
  };
}
