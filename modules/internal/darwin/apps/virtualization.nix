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
  config = mkIf cfg.profile.virtualization.enable {
    homebrew.casks = [
      "utm"
      "container"
    ];
  };
}
