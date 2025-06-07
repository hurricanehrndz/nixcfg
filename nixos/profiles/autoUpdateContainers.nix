{
  config,
  pkgs,
  lib,
  ...
}: let
  containers = config.virtualisation.oci-containers.containers;
  updateScript = lib.concatMapStringsSep "\n" (
    containerName: let
      container = containers.${containerName};
      image = container.image;
    in ''
      echo "Updating ${containerName}..."
      ${pkgs.podman}/bin/podman pull "${image}" || true
      ${pkgs.systemd}/bin/systemctl try-restart podman-${containerName}.service || true
    ''
  ) (builtins.attrNames containers);
in {
  systemd.timers.update-containers = {
    timerConfig = {
      Unit = "update-containers.service";
      OnCalendar = "Mon 02:00";
    };
    wantedBy = ["timers.target"];
  };
  systemd.services.update-containers = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "update-containers" updateScript);
    };
  };
}
