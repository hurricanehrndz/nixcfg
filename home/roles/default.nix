{profiles}:
with profiles; let
  base = [
    zsh
    shellAliases
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
      nvim
    ];
  developer =
    neovim
    ++ [
      aws
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
    developer
    graphical
    ;
}
