{
  home.sessionVariables = {
    # fix double chars
    # see:
    # https://github.com/ohmyzsh/ohmyzsh/issues/7426
    # https://superuser.com/questions/1607527/tab-completion-in-zsh-makes-duplicate-characters
    LC_CTYPE = "C.UTF-8";

    # xdg bin home
    XDG_BIN_HOME = "$HOME/.local/bin";
  };
}
