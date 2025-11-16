{
  pkgs,
  inputs,
  system,
  ...
}:
let
  nixpkgs-pr259776 = import inputs.nixpkgs-pr259776 {
    inherit system;
    config.allowUnfree = true;
  };
  rustdesk = nixpkgs-pr259776.rustdesk.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "rustdesk";
      repo = "rustdesk";
      rev = old.version;
      hash = "sha256-6TdirqEnWvuPgKOLzNIAm66EgKNdGVjD7vf2maqlxI8=";
    };
  });
in
{
  # TODO: Delete -- tested and does not work on headless systems and wayland
  networking.firewall = {
    # 8000 = Rustdesk?
    # 21115-21117 = Rustdesk  https://rustdesk.com/docs/en/self-host/
    # 21118 and 21119 = Rustdesk Web Client
    allowedUDPPorts = [ 21116 ];
    allowedTCPPorts = [
      8000
      21115
      21116
      21117
      21118
      21119
    ];
  };

  environment.systemPackages = [
    rustdesk
  ];

  systemd.tmpfiles.rules = [
    "d /opt/rustdesk 0700 root root"
    "d /var/log/rustdesk 0700 root root"
  ];

  systemd.services.rustdesksignal = {
    description = "Rustdesk Signal Server (hbbs)";
    documentation = [
      "https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/install/"
      "https://github.com/techahold/rustdeskinstall/blob/43df6297a9b8b5ff0f3e05ec4bd6e0f4c7281f88/install.sh"
    ];
    after = [ "network-pre.target" ];
    wants = [ "network-pre.target" ];
    partOf = [ "rustdeskrelay.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      LimitNOFILE = 1000000;
      WorkingDirectory = "/opt/rustdesk";
      StandardOutput = "append:/var/log/rustdesk/hbbs.log";
      StandardError = "append:/var/log/rustdesk/hbbs.error";
      ExecStart = "${pkgs.rustdesk-server}/bin/hbbs -k _";
      Restart = "always";
      RestartSec = 10;
    };
    #script = with pkgs; ''
    #'';
  };

  systemd.services.rustdeskrelay = {
    description = "Rustdesk Relay Server (hbbr)";
    documentation = [
      "https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/install/"
      "https://github.com/techahold/rustdeskinstall/blob/43df6297a9b8b5ff0f3e05ec4bd6e0f4c7281f88/install.sh"
    ];
    after = [ "network-pre.target" ];
    wants = [ "network-pre.target" ];
    partOf = [ "rustdesksignal.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      LimitNOFILE = 1000000;
      WorkingDirectory = "/opt/rustdesk";
      StandardOutput = "append:/var/log/rustdesk/hbbr.log";
      StandardError = "append:/var/log/rustdesk/hbbr.error";
      ExecStart = "${pkgs.rustdesk-server}/bin/hbbr -k _";
      Restart = "always";
      RestartSec = 10;
    };
    #script = with pkgs; ''
    #'';
  };
}
