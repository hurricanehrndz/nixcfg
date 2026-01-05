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
  config = mkIf cfg.roles.guiDeveloper.enable {
    homebrew.casks = [
      "windows-app"
    ];
  };
}
