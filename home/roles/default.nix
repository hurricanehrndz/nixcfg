{profiles}:
with profiles; let
  base = [
    zsh
    shellAliases
    direnv
    git
    tmux
  ];
  roles = {
    inherit
      base
      ;
  };
in
  roles
