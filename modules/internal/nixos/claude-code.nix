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
    environment.systemPackages = [
      inputs.nix-claude-code.packages.${system}.claude
    ];
  };
}
