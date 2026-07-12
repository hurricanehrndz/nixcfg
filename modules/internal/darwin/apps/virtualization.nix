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
  config = mkIf cfg.roles.vmHost.enable {
    environment.systemPackages = with pkgs; [
      # CLI only; dockerd is Linux-only, the daemon lives in lima/container.
      docker-client
      docker-compose
      lazydocker
      tart
      vncdo
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
