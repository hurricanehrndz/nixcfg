{
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
  l = lib // builtins;
in
{
  config = l.mkIf cfg.core.enable {
    # enable management of XDG base directories
    xdg.enable = true;

    # essential tools
    programs.command-not-found.enable = true;
    programs.jq.enable = true;
    programs.man.enable = true;

    # more manpages
    programs.man.generateCaches = l.mkDefault true;

    home.enableNixpkgsReleaseCheck = false;
    home.sessionVariables = {
      # fix dobule chars
      # see:
      # https://github.com/ohmyzsh/ohmyzsh/issues/7426
      # https://superuser.com/questions/1607527/tab-completion-in-zsh-makes-duplicate-characters
      LC_CTYPE = "C.UTF-8";

      # xdg bin home
      XDG_BIN_HOME = "$HOME/.local/bin";
    };
  };
}
