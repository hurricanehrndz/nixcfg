{
  pkgs,
  config,
  inputs,
  system,
  ...
}:
let
  sunshineConfig = pkgs.writeTextDir "config/sunshine.conf" ''
    origin_web_ui_allowed = lan
    adapter_name = /dev/dri/renderD128
    hevc_mode = 1
  '';
  sunshine = inputs.nixpkgs-master.legacyPackages.${system}.sunshine;
in
{
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${sunshine}/bin/sunshine";
  };

  environment.systemPackages = with pkgs; [
    wlr-randr
  ];

  # Inspired from https://github.com/LizardByte/Sunshine/blob/5bca024899eff8f50e04c1723aeca25fc5e542ca/packaging/linux/sunshine.service.in
  systemd.user.services.sunshine = {
    description = "Sunshine server";
    wantedBy = [ "graphical-session.target" ];
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    partOf = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${config.security.wrapperDir}/sunshine ${sunshineConfig}/config/sunshine.conf";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  networking.firewall.allowedTCPPorts = [
    47984
    47989
    47990
    48010
  ];
  networking.firewall.allowedUDPPorts = [
    47998
    47999
    48000
    48002
  ];
}
