{profiles}:
with profiles; let
  base = [
    core
    zsh
    shellAliases
    fzf
    tmux
    gpg
    ssh
    keyboard
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
      direnv
      misc
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
