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
      aws
      # devenv
    ];
  graphical = [
    wezterm
    amethyst
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
