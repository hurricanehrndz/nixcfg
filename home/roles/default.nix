{profiles}:
with profiles; let
  base = [
    core
    zsh
    shellAliases
    fzf
    tmux
    direnv
    gpg
    ssh
  ];
  neovim =
    base
    ++ [
      editorconfig
      git
      lazygit
      pdenv
    ];
  remote =
    base
    ++ [
      editorconfig
      git
      lazygit
      pdenv
    ];
  developer =
    neovim
    ++ [
      encryption
    ];
  graphical = [
    wezterm
    tillingwm
    ghostty
    # keyboard # yabai keybindings via skhdrc
  ];
in {
  inherit
    base
    neovim
    remote
    nvim-only
    developer
    graphical
    ;
}
