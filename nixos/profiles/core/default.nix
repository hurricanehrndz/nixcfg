{
  lib,
  pkgs,
  ...
}: {
  # If this were enabled, rebuilds will take... a very long time.
  documentation.info.enable = false;

  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    # system info
    dmidecode
    pciutils
    sysstat
    usbutils
    util-linux

    # networking
    inetutils
    iputils
    ethtool
    fast-cli

    # filesystems
    exfat
    exfatprogs
    dosfstools
    gptfdisk
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
  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Service that makes Out of Memory Killer more effective
  services.earlyoom.enable = true;
}
