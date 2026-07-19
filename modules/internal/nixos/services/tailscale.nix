{
  self,
  config,
  lib,
  isBootstrap ? false,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.hrndz.services.tailscale;
in
{
  options.hrndz.services.tailscale = {
    enable = mkEnableOption "Tailscale mesh VPN, joined non-interactively with the shared agenix auth key";

    extraUpFlags = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "--advertise-exit-node" ];
      description = "Extra flags passed to `tailscale up` on first connect.";
    };
  };

  # The auth key lives at secrets/services/tailscale/auth.age and is decryptable
  # by every host listed in secrets/secrets.nix, so enabling the service is all a
  # host needs to do. Rotate the key there when it expires.
  config = mkIf (cfg.enable && !isBootstrap) {
    age.secrets."tailscale-auth".file = "${self}/secrets/services/tailscale/auth.age";

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."tailscale-auth".path;
      inherit (cfg) extraUpFlags;
    };
  };
}
