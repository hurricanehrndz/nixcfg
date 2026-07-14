{ lib, config, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.hrndz;
in
{
  options.hrndz = {
    tooling = {
      macAdmin.enable = mkEnableOption "Enable MacAdmin tooling";

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

      zig.enable = mkEnableOption "Enable Zig tooling";

      documentTools.enable = mkEnableOption "Enable document authoring and conversion tooling";
    };

    roles = {
      terminalUser.enable = mkEnableOption "Enable the terminal user environment";

      terminalDeveloper.enable = mkEnableOption "Enable terminal-based development environment";

      developerWorkstation.enable = mkEnableOption "Enable the graphical developer workstation";

      vmHost.enable = mkEnableOption "Enable VM hosting";
    };
  };

  config.hrndz = mkMerge [
    (mkIf cfg.roles.terminalDeveloper.enable {
      roles.terminalUser.enable = true;
    })

    (mkIf cfg.roles.developerWorkstation.enable {
      roles.terminalDeveloper.enable = true;
    })

    (mkIf cfg.roles.vmHost.enable {
      roles.terminalUser.enable = true;
    })
  ];
}
