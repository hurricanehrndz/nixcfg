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
    # spin up project-specific development environments
    home.packages = with pkgs; [
      devenv
      mise
    ];
  };
}
