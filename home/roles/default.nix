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
      direnv
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
