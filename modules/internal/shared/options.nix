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

    tooling = {
      # darwin only
      virtualization.enable = mkEnableOption "Enable virtualization tooling" // {
        default = false;
      };

      macadmin.enable = mkEnableOption "Enable MacAdmin tooling" // {
        default = false;
      };

      python.enable = mkEnableOption "Enable Python tooling" // {
        default = false;
      };

      ruby.enable = mkEnableOption "Enable Ruby tooling" // {
        default = false;
      };
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
