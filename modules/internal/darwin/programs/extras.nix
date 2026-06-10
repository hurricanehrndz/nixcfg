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
  config = mkIf cfg.tooling.extras.enable {
    homebrew = {
      taps = [
        "1jehuang/mmdr"
      ];
      brews = [
        "makensis"
        "mmdr"
        "sem-cli"
      ];
    };
  };
}
