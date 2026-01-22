{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    documentation.dev.enable = true;
  };
}
