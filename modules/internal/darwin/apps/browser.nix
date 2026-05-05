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
    environment.systemPackages = [ pkgs.brave-origin-beta ];

    homebrew.casks = [
      "firefox"
    ];
  };
}
