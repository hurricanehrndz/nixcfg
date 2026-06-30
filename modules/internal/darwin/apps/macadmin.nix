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
    homebrew.brews = [
      "carthage"
      "makensis"
    ];
    homebrew.casks = [
      "apparency"
      # "suspicious-package" # disable - causing install issues
    ];
  };
}
