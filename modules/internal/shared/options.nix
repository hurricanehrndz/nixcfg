{ lib, config, ... }:
let
  inherit (lib) mkEnableOption;

  cfg = config.hrndz;
in
{
  options.hrndz = {
    core.enable = mkEnableOption "Enable minimal options" // {
      default = true;
    };

    tui.enable = mkEnableOption "Enable CLI/TUI programs" // {
      default = cfg.core.enable;
    };

    devEnv.enable = mkEnableOption "Enable development environment" // {
      default = true;
    };
  };
}
