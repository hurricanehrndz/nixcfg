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
  config = mkIf cfg.roles.guiDeveloper.enable {
    hrndz.services.aerospace.enable = true;
    hrndz.services.aerospace.package = pkgs.unstable.aerospace;
    hrndz.services.aerospace.settings = builtins.readFile ./aerospace.toml;
  };
}
