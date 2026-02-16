{
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    programs.man.enable = true;

    # more manpages
    programs.man.generateCaches = mkDefault true;

    # home-manager docs
    manual.json.enable = true;
    manual.manpages.enable = true;
  };
}
