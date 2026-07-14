{
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
  config = mkIf cfg.tooling.zig.enable {
    home.packages = [ pkgs.zig ];
  };
}
