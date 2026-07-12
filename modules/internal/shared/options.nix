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
    cli.enable = mkEnableOption "Enable CLI/TUI programs";

    tooling = {
      macadmin.enable = mkEnableOption "Enable MacAdmin tooling";

      python.enable = mkEnableOption "Enable Python tooling";

      ruby.enable = mkEnableOption "Enable Ruby tooling";

      js.enable = mkEnableOption "Enable JavaScript tooling";

      ai = {
        enable = mkEnableOption "Enable AI tooling";

        # omlx and friends load large MLX models into RAM, so only enable this
        # on hosts with ample memory (>=30GB). Off by default; flip on per-host.
        localInference.enable = mkEnableOption "Enable local LLM inference tooling (omlx)";
      };

      golang.enable = mkEnableOption "Enable Golang tooling";

      extras.enable = mkEnableOption "Enable extra cmdline utils";
    };

    roles = {
      terminalDeveloper.enable = mkEnableOption "Enable terminal-based development environment";

      guiDeveloper.enable = mkEnableOption "Enable graphical-based development environment";

      vmHost.enable = mkEnableOption "Enable VM hosting";
    };
  };

  config.hrndz = mkMerge [
    (mkIf cfg.roles.terminalDeveloper.enable {
      cli.enable = mkDefault true;
    })

    (mkIf cfg.roles.guiDeveloper.enable {
      roles.terminalDeveloper.enable = true;
    })

    (mkIf cfg.roles.vmHost.enable {
      roles.terminalDeveloper.enable = true;
    })
  ];
}
