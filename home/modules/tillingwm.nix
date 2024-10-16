{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  tomlFormat = pkgs.formats.toml {};
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = config.services.tillingwm;
in {
  options = {
    services.tillingwm.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable a tiling window manager.";
    };

    services.tillingwm.settings = mkOption {
      type = tomlFormat.type;
      default = {};
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          start-at-login = false;
        }
      '';
      description = ''
        Configuration written to
        <filename>$HOME/.aerospace.toml</filename> on Darwin. See
        <link xlink:href="https://nikitabobko.github.io/AeroSpace/guide"/>
        for supported values.
      '';
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> isDarwin;
          message = "This tillingwm is only supported on darwin";
        }
      ];
    }

    (mkIf cfg.enable {
        xdg.configFile."aerospace/aerospace.toml" = {
        source = tomlFormat.generate "tillingwm-config" cfg.settings;
      };

      # launchd.agents.amethyst = {
      #   enable = lib.mkDefault true;
      #   config = {
      #     ProgramArguments = [
      #       "/Applications/Amethyst.app/Contents/MacOS/Amethyst"
      #     ];
      #     KeepAlive = true;
      #     ProcessType = "Interactive";
      #   };
      # };
    })
  ];
}
