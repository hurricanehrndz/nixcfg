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
      nvim
    ];
  roles = {
    inherit
      base
      developer
      ;
  };
in
  roles
