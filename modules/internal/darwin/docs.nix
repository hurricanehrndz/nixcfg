{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    documentation.enable = true;
    environment.systemPackages = [
      inputs.determinate-nix.packages.nix-manual
    ];
  };
}
