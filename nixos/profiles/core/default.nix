{
  config,
  lib,
  pkgs,
  ...
}: {
  # If this were enabled, rebuilds will take... a very long time.
  documentation.info.enable = false;

  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    settings = {
      system-features = ["nixos-test" "benchmark" "big-parallel" "kvm"];
    };
    gc.dates = "weekly";
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    dosfstools
    gptfdisk
    inetutils
    iputils
    pciutils
    sysstat
    usbutils
    util-linux
  ];

  programs.git.enable = true;
  programs.git.config = {
    safe.directory = [
      "/etc/nixos"
      "/etc/nixcfg"
    ];
  };

  programs.command-not-found.enable = true;
  programs.htop.enable = true;
  programs.mtr.enable = true;

  services.openssh = {
    enable = lib.mkForce true;
    openFirewall = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = lib.mkForce "no";
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };

  # Allow passwordless sudo within an SSH session.
  security.pam.sshAgentAuth.enable = true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Service that makes Out of Memory Killer more effective
  services.earlyoom.enable = true;
}
