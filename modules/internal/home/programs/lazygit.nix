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
    programs.zsh.initContent = lib.mkOrder 1090 ''
      alias v="nvim"
      if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
        export EDITOR="nvr -s -cc '"LazygitCloseFocusLargest"' &&  nvr "
        export VISUAL="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
        alias vi="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
        alias vim="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
        alias nvim="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
        alias v="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
      fi
      alias gitlint="gitlint --contrib=CT1 --ignore body-is-missing,T3 -c T1.line-length=50 -c B1.line-length=72"
    '';
  };
}
