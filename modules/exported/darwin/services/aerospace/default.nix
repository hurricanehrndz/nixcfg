{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkPackageOption
    mkEnableOption
    types
    literalExpression
    optionalString
    ;
  cfg = config.hrndz.services.aerospace;
  configFile = pkgs.writeTextFile "aerospace.toml" {
    text = cfg.settings;
  };
in
{
  options.hrndz.services.aerospace = {
    enable = mkEnableOption "AeroSpace window manager";

    package = mkPackageOption pkgs "aerospace" { };

    settings = mkOption {
      type = types.str;
      example = literalExpression ''
        start-at-login = false
        [key-mapping]
        preset = 'qwerty'
      '';
      description = ''
        Configuration written to
        <filename>/nix/store/.../aerospace.toml</filename> on Darwin. See
        <link xlink:href="https://nikitabobko.github.io/AeroSpace/guide"/>
        for supported values.
      '';
    };
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.aerospace = {
      command =
        "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
        + (optionalString (cfg.settings != "") " --config-path ${configFile}");
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
      };
      managedBy = "hrndz.services.aerospace.enable";
    };
  };
}
