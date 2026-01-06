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
  config = mkIf cfg.tooling.virtualization.enable {
    homebrew.casks = [
      "utm"
    ];

    homebrew.brews = [
      "container"
    ];
  };
}
