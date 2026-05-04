{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./users/hurricane.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "Lucy";
  networking.domain = "hrndz.ca";

  hrndz.tooling.virtualization = {
    enable = true;
    hardware.cpuVendor = "intel";
    users = [ "hurricane" ];

    vfio = {
      enable = true;
      ignoreMsrs = true;
    };
  };

  hrndz.desktop.hyprland = {
    autologin = {
      enable = true;
      user = "hurricane";
    };

    remote = {
      enable = true;
      bind = "127.0.0.1";
      port = 5900;
    };

    terminal = "ghostty";
    launcher = "rofi -show drun";

    theme = {
      source = "omarchy";
      variant = "light";
    };
  };

  system.primaryUser = "hurricane";
  system.stateVersion = "25.11";
}
