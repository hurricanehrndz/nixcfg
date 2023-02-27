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
