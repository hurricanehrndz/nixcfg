{profiles}:
with profiles; let
  base = [
    zsh
    shellAliases
    tmux
  ];
  developer =
    base
    ++ [
      aws
      direnv
      editorconfig
      git
      gpg
      lazygit
      nvim
    ];
  graphical = [
    wezterm
    amethyst
    # keyboard # yabai keybindings via skhdrc
  ];
  roles = {
    inherit
      base
      developer
      graphical
      ;
  };
in
  roles
