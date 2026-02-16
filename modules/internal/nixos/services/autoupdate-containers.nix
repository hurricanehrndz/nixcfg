{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  containers = config.virtualisation.oci-containers.containers;
  updateScript = lib.concatMapStringsSep "\n" (
    containerName:
    let
      container = containers.${containerName};
      image = container.image;
    in
    ''
      echo "Updating ${containerName}..."
      if ${pkgs.podman}/bin/podman pull "${image}"; then
        ${pkgs.systemd}/bin/systemctl restart podman-${containerName}.service || true
      else
        echo "Failed to pull ${image}, skipping restart of ${containerName}" >&2
      fi
    ''
  ) (builtins.attrNames containers);
  cfg = config.hrndz.services.autoUpdateContainers;
in
{
  options.hrndz.services.autoUpdateContainers = {
    enable = mkEnableOption "Enable auto updating of OCI containers";
  };

  config = mkIf cfg.enable {
    systemd.timers.update-containers = {
      timerConfig = {
        Unit = "update-containers.service";
        OnCalendar = "Mon 02:00";
      };
      wantedBy = [ "timers.target" ];
    };
    systemd.services.update-containers = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe (pkgs.writeShellScriptBin "update-containers" updateScript);
      };
    };
  };
}
