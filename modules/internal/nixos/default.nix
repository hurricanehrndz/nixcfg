{ lib, pkgs, ... }:
let
  inherit (lib) mkDefault mkForce;
in
{
  ##: packages
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

  ##: programs
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

  ##: openssh
  services.openssh = {
    enable = mkForce true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = mkForce "no";
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      MaxAuthTries = 5;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };

  ##: security
  security.pam.sshAgentAuth.enable = true;
  security.pam.sshAgentAuth.authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];

  ##: hardware
  hardware.enableRedistributableFirmware = mkDefault true;

  ##: services
  services.earlyoom.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
  '';

  ##: kernel
  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = mkDefault true;
    "net.ipv4.conf.all.accept_redirects" = mkDefault false;
    "net.ipv4.conf.default.accept_redirects" = mkDefault false;
    "net.ipv6.conf.all.accept_redirects" = mkDefault false;
    "net.ipv6.conf.default.accept_redirects" = mkDefault false;
    "net.ipv4.conf.all.send_redirects" = mkDefault false;
    "net.ipv4.conf.default.send_redirects" = mkDefault false;
    "net.ipv4.conf.all.accept_source_route" = mkDefault false;
    "net.ipv4.conf.default.accept_source_route" = mkDefault false;
    "net.ipv6.conf.all.accept_source_route" = mkDefault false;
    "net.ipv6.conf.default.accept_source_route" = mkDefault false;
  };

  ##: stateVersion
  system.stateVersion = mkDefault "25.11";
}
