{
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    services.tillingwm.enable = true;
    services.tillingwm.settings = builtins.readFile ./config.toml;
    launchd.agents.aerospace = {
      enable = true;
      config = {
        Program = "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
        ProgramArguments = [
          "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
        ];
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
      };
    };
  })
]
