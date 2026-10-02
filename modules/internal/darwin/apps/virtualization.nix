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
      libvirt # virsh client; windows-test-rig drives remote libvirt hosts over qemu+ssh
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
