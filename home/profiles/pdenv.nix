{
  inputs',
  pkgs,
  ...
}: let
  nvim-pdenv = inputs'.pdenv.packages.pdenv;
in {
  home.packages = with pkgs; [
    nvim-pdenv
    neovim-remote
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
    alias v="nvim"
  '';
}
