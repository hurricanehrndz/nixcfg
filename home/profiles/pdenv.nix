{
  inputs',
  pkgs,
  lib,
  ...
}:
let
  nvim-pdenv = inputs'.pdenv.packages.pdenv;
in
{
  home.packages = with pkgs; [
    gh
    ghostscript
    gitlint
    imagemagick
    neovim-remote
    nodePackages_latest.prettier
    nvim-pdenv
    ruff
    shfmt
    slides
    zig
    zk
  ];
  programs.zsh.initContent = lib.mkOrder 1090 ''
    alias v="nvim"
    if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
      export EDITOR="nvr -s -cc '"LazygitCloseFocusLargest"' &&  nvr "
      export VISUAL="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
      alias vi="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
      alias vim="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
      alias nvim="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
      alias v="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
    fi
    alias gitlint="gitlint --contrib=CT1 --ignore body-is-missing,T3 -c T1.line-length=50 -c B1.line-length=72"
  '';
}
