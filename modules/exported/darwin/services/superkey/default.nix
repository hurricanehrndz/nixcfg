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
      serviceConfig = {
        Program = "/Applications/Superkey.app/Contents/MacOS/Superkey";
        ProgramArguments = [
          "/Applications/Superkey.app/Contents/MacOS/Superkey"
        ];
        KeepAlive = true;
        RunAtLoad = true;
      };
      managedBy = "hrndz.services.superkey.enable";
    };

    system.defaults.CustomUserPreferences = {
      "com.knollsoft.Superkey" = {
        SUEnableAutomaticChecks = 0;
        SUHasLaunchedBefore = 1;
        capsLockKeycode = "-1";
        capsLockRemapped = 2;
        executeQuickHyperKey = 2;
        hyperFlags = 1966080;
        keyRemap = 1;
        launchOnLogin = 0;
        mehKeycode = 57;
        mehRemap = 1;
        modifierSeekMode = 2;
        physicalKeycode = 230;
        quickHyperKeycode = 53;
        statusIcon = 2;
      };
    };
  };
}
