{
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  # enable skhd here, because it autoreloads config on changes
  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    launchd.agents.superkey = {
      enable = true;
      config = {
        Program = "/Applications/Superkey.app/Contents/MacOS/Superkey";
        ProgramArguments = [
          "/Applications/Superkey.app/Contents/MacOS/Superkey"
        ];
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
      };
    };
  })
]
