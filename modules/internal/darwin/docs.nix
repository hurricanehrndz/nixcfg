{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    documentation.enable = true;
    environment.systemPackages = [
      inputs.determinate-nix.packages.${system}.nix-manual
    ];
  };
}
