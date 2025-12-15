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
    core.enable = mkEnableOption "Enable minimal options" // {
      default = true;
    };

    tui.enable = mkEnableOption "Enable CLI/TUI programs" // {
      default = false;
    };

    profile.virtualization = mkEnableOption "Enable virtualization programs" // {
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
      core.enable = mkDefault true;
      tui.enable = mkDefault true;
    })

    (mkIf cfg.roles.guiDeveloper.enable {
      roles.terminalDeveloper.enable = true;
    })
  ];
}
