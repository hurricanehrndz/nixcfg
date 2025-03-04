{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.superkey;
in {
  options.programs.superkey = {
    enable = mkEnableOption "Enable superkey.";

    username = mkOption {
      type = types.str;
      default = "chernand";
      description = ''
        Primary macOS user.
      '';
    };
  };
  config = mkIf cfg.enable {
    homebrew.casks = [
      "superkey"
    ];
    home-manager.users.${cfg.username} = {pkgs, ...}: {
      launchd.agents.superkey = {
        enable = true;
        config = {
          Program = "/Applications/Superkey.app/Contents/MacOS/Superkey";
          ProgramArguments = [
            "/Applications/Superkey.app/Contents/MacOS/Superkey"
          ];
          RunAtLoad = true;
        };
      };
    };
    system.defaults.CustomUserPreferences = {
      "com.knollsoft.Superkey" = {
        "NSWindow Frame EntryBarWindow" = "1720 1151 400 40 0 0 3840 1575 ";
        SUEnableAutomaticChecks = 0;
        SUHasLaunchedBefore = 1;
        capsLockRemapped = 2;
        executeQuickHyperKey = 1;
        hyperFlags = 1966080;
        keyRemap = 1;
        lastVersion = 41;
        launchOnLogin = 0;
        mehKeycode = 57;
        mehRemap = 1;
        physicalKeycode = 230;
        quickHyperKeycode = 53;
        statusIcon = 2;
      };
    };
  };
}
