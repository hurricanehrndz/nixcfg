{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.hrndz.services.superkey;
in
{
  options.hrndz.services.superkey = {
    enable = mkEnableOption "Enable superkey.";
  };
  config = mkIf cfg.enable {
    homebrew.casks = [
      "superkey"
    ];

    launchd.user.agents.superkey = {
      command = "/Applications/Superkey.app/Contents/MacOS/Superkey";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
      };
      managedBy = "hrndz.services.superkey.enable";
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
