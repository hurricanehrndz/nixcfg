{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.roles.developerWorkstation.enable {
    homebrew.casks = [
      "tailscale-app"
    ];

    # tsdns gives split DNS while Tailscale runs with --accept-dns=false.
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "tsdns";
        text = builtins.readFile ./tsdns.sh;
      })
    ];
  };
}
