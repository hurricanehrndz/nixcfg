{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.aerospace;
in {
  options.programs.aerospace = {
    enable = mkEnableOption "Enable aerospace.";

    username = mkOption {
      type = types.str;
      default = "chernand";
      description = ''
        Primary macOS user.
      '';
    };

    settings = mkOption {
      type = types.str;
      example = literalExpression ''
        start-at-login = false
        [key-mapping]
        preset = 'qwerty'
      '';
      description = ''
        Configuration written to
        <filename>$HOME/.aerospace.toml</filename> on Darwin. See
        <link xlink:href="https://nikitabobko.github.io/AeroSpace/guide"/>
        for supported values.
      '';
    };
  };
  config = mkIf cfg.enable {
    homebrew = {
      taps = [
        "nikitabobko/tap"
      ];
      casks = [
        "aerospace"
      ];
      brews = [
        "brew-install-path"
      ];
    };
    home-manager.users.${cfg.username} = {pkgs, ...}: {
      xdg.configFile."aerospace/aerospace.toml" = {
        text = cfg.settings;
      };

      launchd.agents.aerospace = {
        enable = true;
        config = {
          Program = "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
          ProgramArguments = [
            "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}
