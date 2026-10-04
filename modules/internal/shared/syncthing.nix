{
  self,
  config,
  lib,
  pkgs,
  isBootstrap ? false,
  ...
}:
let
  cfg = config.hrndz.services.syncthing;
in
{
  # The Syncthing service itself is configured in
  # modules/internal/home/programs/syncthing.nix.
  options.hrndz.services.syncthing.enable =
    lib.mkEnableOption "Syncthing vault sync through the DeepThought hub";

  config = lib.mkIf (cfg.enable && !isBootstrap) {
    age.secrets."syncthing-key" = {
      file = "${self}/secrets/services/syncthing/${config.networking.hostName}/key.pem.age";
      owner = config.system.primaryUser;
      group = if pkgs.stdenv.hostPlatform.isDarwin then "staff" else "users";
    };
  };
}
