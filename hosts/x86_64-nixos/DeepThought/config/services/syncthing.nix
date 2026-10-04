{
  self,
  config,
  lib,
  isBootstrap ? false,
  ...
}:
let
  user = config.system.primaryUser;
  guiPath = "/syncthing";
in
{
  # Hub for the vaults. Device and folder wiring lives in
  # modules/internal/home/programs/syncthing.nix.
  hrndz.services.syncthing.enable = true;

  # Syncthing is a user service; keep it running without a login.
  users.users.${user}.linger = true;

  # Sync port on the LAN and the tailnet only.
  networking.firewall.interfaces =
    lib.genAttrs
      [
        "enp0s31f6"
        "tailscale0"
      ]
      (_: {
        allowedTCPPorts = [ 22000 ];
        allowedUDPPorts = [ 22000 ];
      });

  systemd.tmpfiles.rules = [ "d /volumes/vaults 0750 ${user} users -" ];

  age.secrets = lib.mkIf (!isBootstrap) {
    "syncthing-gui-password" = {
      file = "${self}/secrets/services/syncthing/DeepThought/gui-password.age";
      owner = user;
    };
  };

  home-manager.users.${user}.services.syncthing = lib.mkIf (!isBootstrap) {
    guiCredentials = {
      username = user;
      passwordFile = config.age.secrets."syncthing-gui-password".path;
    };
    settings.folders.personal.path = "/volumes/vaults/personal";
  };

  # The GUI listens on loopback; Traefik serves it under a path on the host's
  # existing name.
  hrndz.services.ingress.extraConfig.syncthing =
    lib.mkIf (!isBootstrap && config.hrndz.services.ingress.enable)
      {
        http = {
          routers.syncthing = {
            rule = "Host(`${config.networking.hostName}.${config.networking.domain}`) && PathPrefix(`${guiPath}`)";
            entryPoints = [ "websecure" ];
            tls.certResolver = "default";
            middlewares = [
              "syncthing-slash"
              "syncthing-strip"
            ];
            service = "syncthing";
          };
          # The GUI loads its assets by relative URL, so it needs the trailing slash.
          middlewares.syncthing-slash.redirectRegex = {
            regex = "^(https?://[^/]+${guiPath})$";
            replacement = "\${1}/";
            permanent = true;
          };
          middlewares.syncthing-strip.stripPrefix.prefixes = [ guiPath ];
          # Syncthing rejects a Host header that isn't its own listen address.
          services.syncthing.loadBalancer = {
            servers = [ { url = "http://127.0.0.1:8384"; } ];
            passHostHeader = false;
          };
        };
      };
}
