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
  config = mkIf cfg.profile.macadmin.enable {
    homebrew.casks = [
      "apparency"
      "suspicious-package"
    ];
  };
}
