{ lib, config, ... }:
let
  inherit (lib)
    mkEnableOption
    mkDefault
    mkIf
    mkMerge
    ;
  cfg = config.hrndz;
in
{
  options.hrndz = {
    tui.enable = mkEnableOption "Enable CLI/TUI programs";

    tooling = {
      # darwin only
      virtualization.enable = mkEnableOption "Enable virtualization tooling";

      macadmin.enable = mkEnableOption "Enable MacAdmin tooling";

      python.enable = mkEnableOption "Enable Python tooling";

      ruby.enable = mkEnableOption "Enable Ruby tooling";
    };

    roles.terminalDeveloper.enable = mkEnableOption "Enable terminal-based development environment";

    roles.guiDeveloper.enable = mkEnableOption "Enable graphical-based development environment";
  };

  config.hrndz = mkMerge [
    (mkIf cfg.roles.terminalDeveloper.enable {
      tui.enable = mkDefault true;
    })

    (mkIf cfg.roles.guiDeveloper.enable {
      roles.terminalDeveloper.enable = true;
    })
  ];
}
