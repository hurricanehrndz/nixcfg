{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
  inherit (cfg.theme) scheme;
in
{
  config = lib.mkIf cfg.roles.terminalUser.enable {
    home.packages = with pkgs; [
      # Bash scripts that integrate bat with various command line tools.
      # https://github.com/eth-p/bat-extras/
      bat-extras.batman # <- Read system manual pages (man) using bat as the manual page formatter.
      bat-extras.batgrep # <- Quickly search through and highlight files using ripgrep.
      bat-extras.batdiff # <- Diff a file against the current git index, or display the diff between two files.
      bat-extras.batwatch # <- Watch for changes in files or command output, and print them with bat.
      bat-extras.prettybat # <- Pretty-print source code and highlight it with bat.
    ];

    programs.bat = {
      enable = true;
      config = {
        # Otherwise Stylix supplies base16-stylix (see ../theme.nix).
        theme = lib.mkIf (lib.hasPrefix "catppuccin-" scheme) (
          "Catppuccin " + lib.toSentenceCase (lib.removePrefix "catppuccin-" scheme)
        );
        style = "numbers,changes,header";
        italic-text = "always";
        pager = "less -RFK";
        map-syntax = [
          ".*ignore:Git Ignore"
          ".gitconfig.local:Git Config"
          "**/mx*:Bourne Again Shell (bash)"
          "**/completions/_*:Bourne Again Shell (bash)"
          ".vimrc.local:VimL"
          "vimrc:VimL"
        ];
      };
    };
  };
}
