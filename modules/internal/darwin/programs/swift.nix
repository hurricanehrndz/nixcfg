{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.hrndz.roles.swiftDeveloper;
in
{
  options.hrndz.roles.swiftDeveloper.enable = mkEnableOption "Enable Swift development tooling";

  config = mkIf cfg.enable {
    hrndz.roles.terminalDeveloper.enable = true;

    environment.systemPackages = with pkgs; [
      swiftformat
      swiftlint
      tuist
    ];
  };
}
