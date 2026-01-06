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
    tui.enable = mkEnableOption "Enable CLI/TUI programs" // {
      default = false;
    };

    profile.virtualization.enable = mkEnableOption "Enable virtualization programs" // {
      default = false;
    };

    profile.macadmin.enable = mkEnableOption "Enable MacAdmin tooling" // {
      default = false;
    };

    roles.terminalDeveloper.enable = mkEnableOption "Enable terminal-based development environment" // {
      default = false;
    };

    roles.guiDeveloper.enable = mkEnableOption "Enable graphical-based development environment" // {
      default = false;
    };
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
