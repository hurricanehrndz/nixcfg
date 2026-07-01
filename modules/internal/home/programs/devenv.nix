{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    # spin up devenv-based dev environments in other projects
    home.packages = with pkgs; [ devenv ];
  };
}
