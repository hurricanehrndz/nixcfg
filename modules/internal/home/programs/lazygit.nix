{
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        promptToReturnFromSubprocess = false;
        # moved to pdenv
        # os = {
        #   edit = "nvr -s -l {{filename}}"; # see 'Configuring File Editing' section
        #   editAtLine = "nvr -s -l +{{line}} -- {{filename}}";
        # };
        gui = {
          nerdFontsVersion = "3";
        };
        git = {
          autoFetch = false;
          autoRefresh = false;
        };
        keybinding = {
          files = {
            commitChanges = "C";
            commitChangesWithEditor = "c";
          };
        };
      };
    };
  };
}
