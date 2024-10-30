{
  inputs',
  pkgs,
  packages,
  ...
}: let
  nvim-pdenv = inputs'.pdenv.packages.pdenv;
in {
  home.packages = with pkgs; [
    nvim-pdenv
    neovim-remote
    shfmt
    nodePackages_latest.prettier
    ruff
    ruff-lsp
    gitlint
    packages.keg
    gh
  ];
  programs.zsh.initExtra = ''
    if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
      export EDITOR="nvr -l"
      export VISUAL="nvr --remote-tab-silent"
      alias vi="nvr -l"
      alias vim="nvr -l"
      alias nvim="nvr -l"
      alias v="nvr -l"
    fi
    alias gitlint="gitlint --contrib=CT1 --ignore body-is-missing,T3 -c T1.line-length=50 -c B1.line-length=72"
    alias v="nvim"
    alias pdenv="~/src/me/pdenv/result/bin/nvim"
  '';
}
