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
  config = mkIf cfg.tooling.virtualization.enable {
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
      lazydocker
    ];

    homebrew.casks = [
      "utm"
    ];

    homebrew.brews = [
      "container"
      "lima"
    ];
  };
}
