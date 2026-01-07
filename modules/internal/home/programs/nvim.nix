{
  inputs',
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
  nvim-pdenv = inputs'.pdenv.packages.pdenv;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    home.packages = with pkgs; [
      neovim-remote
      nvim-pdenv
      # viewers
      ghostscript # see pdf
      imagemagick # see images
      # formatters
      nodePackages_latest.prettier # formatter
      shfmt
      # linters
      gitlint
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
  };
}
