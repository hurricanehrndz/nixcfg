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
  config = mkIf cfg.tooling.macadmin.enable {
    homebrew.casks = [
      "apparency"
      "suspicious-package"
    ];
  };
}
