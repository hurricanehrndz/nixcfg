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
          KeepAlive.SuccessfulExit = false;
        };
      };
    };
  };
}
