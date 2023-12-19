{
  self,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.domain = "hrndz.ca";

  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = ["/var/lib/home-assistant:/config"];
      environment.TZ = "America/Edmonton";
      image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
      extraOptions = [
        "--network=host"
        "--pull=always"
      ];
    };
    containers.zwavejs = {
      volumes = ["/var/lib/zwavejs:/usr/src/app/store"];
      ports = [
        "8091:8091"
        "3000:3000"
      ];
      environment.TZ = "America/Edmonton";
      image = "zwavejs/zwave-js-ui:latest";
      extraOptions = [
        "--pull=always"
        "--device=/dev/serial/by-id/usb-Silicon_Labs_Zooz_ZST10_700_Z-Wave_Stick_9a08dfb2ac21ec11bb06be942c86906c-if00-port0:/dev/zwave:rw" # Example, change this to match your own hardware
      ];
    };
  };

  system.activationScripts.zwaveDirs = ''
    mkdir -p /var/lib/{zwavejs,home-assistant}
  '';

  systemd.services."systemd-backlight@".enable = false;

  services.upower.ignoreLid = true;
  services.logind.lidSwitch = "ignore";

  networking.firewall.allowedTCPPorts = [8123 8091];

  system.stateVersion = "23.11";
}
# vim: set et sw=2 :
