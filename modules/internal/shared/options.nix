{ lib, config, ... }:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
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

      atlassianCli.enable = mkEnableOption "Enable Atlassian CLI tools";
    };

    theme = {
      scheme = mkOption {
        type = types.str;
        default = "catppuccin-latte";
        example = "rose-pine-dawn";
        description = "base16 scheme (tinted-theming name) used for terminal tools.";
      };

      ghostty = mkOption {
        type = types.nullOr types.str;
        default = "noctis-lux";
        description = "Ghostty theme name, or null to use the scheme.";
      };

      unified = mkEnableOption "the scheme everywhere, Ghostty included";
    };

    roles = {
      terminalUser.enable = mkEnableOption "Enable the terminal user environment";

      terminalDeveloper.enable = mkEnableOption "Enable terminal-based development environment";

      developerWorkstation.enable = mkEnableOption "Enable the graphical developer workstation";

      vmHost.enable = mkEnableOption "Enable VM hosting";
    };
  };

  config.hrndz = mkMerge [
    (mkIf cfg.theme.unified {
      theme.ghostty = mkDefault null;
    })

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
