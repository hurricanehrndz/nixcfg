{
  config,
  pkgs,
  ...
}: {
  systemd.services."websockify" = {
    description = "Service to forward websocket connections to TCP connections";
    script = ''
      ${pkgs.python3Packages.websockify}/bin/websockify :5959 127.0.0.1:5901
    '';
    wantedBy = ["multi-user.target"];
  };

  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      forceSSL = false;
      root = "/var/www/";
      locations."/spice/" = {
        index = "index.html index.htm";
      };
      listen = [
        {
          addr = "*";
          port = 45000;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [45000 5959];
}
