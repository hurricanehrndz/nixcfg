{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  yamlFormat = pkgs.formats.yaml {};
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = config.services.amethyst;
in {
  options = {
    services.amethyst.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the Amethyst tiling window manager.";
    };

    services.amethyst.settings = mkOption {
      type = yamlFormat.type;
      default = {};
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          layouts = [
            "tall"
          ];
        }
      '';
      description = ''
        Configuration written to
        <filename>$HOME/.amethyst.yml</filename> on Darwin. See
        <link xlink:href="https://github.com/ianyh/Amethyst/blob/development/docs/configuration-files.md"/>
        for supported values.
      '';
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> isDarwin;
          message = "Amethyst is only supported on darwin";
        }
      ];
    }

    (mkIf cfg.enable {
      home.file.".amethyst.yml" = {
        source = yamlFormat.generate "amethyst-config" cfg.settings;
      };

      launchd.agents.amethyst = {
        enable = lib.mkDefault true;
        config = {
          ProgramArguments = [
            "/Applications/Amethyst.app/Contents/MacOS/Amethyst"
          ];
          KeepAlive = true;
          ProcessType = "Interactive";
        };
      };
    })
  ];
}
