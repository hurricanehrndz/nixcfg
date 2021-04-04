{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.shell;
in
{
  options.hurricane = {
    configs.shell.enable = mkEnableOption "enable awsome zsh config";
  };
  config = mkIf cfg.enable {
    # Enable shell management
    programs.zsh = {
      enable = true;
      autocd = true;
      enableCompletion = false; # Enable when ready
      defaultKeymap = "viins";
      dotDir = ".config/zsh";
      history = {
        extended = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        path =  "${config.xdg.configHome}/zsh/zsh_history";
      };
      shellAliases = with pkgs; {
        # Aliases that make commands colourful.
        "grep" = "${gnugrep}/bin/grep --color=auto";
        "fgrep" = "${gnugrep}/bin/fgrep --color=auto";
        "egrep" = "${gnugrep}/bin/egrep --color=auto";
        # exa
        "ls" = "${exa}/bin/exa";
        "ll" = "${exa}/bin/exa -lhF --group-directories-first";
        "la" = "${exa}/bin/exa -alhF --group-directories-first";
        "lt" = "${exa}/bin/exa -alhF --sort modified";
        "l"  = "${exa}/bin/exa -1 --group-directories-first -F";
        "tree" = "${exa}/bin/exa -T";
        # Aliases for `cat` to `bat`.
        "cat" = "${bat}/bin/bat --theme ansi-dark";

      };
      initExtra = ''
        source "${pkgs.grc}/etc/grc.zsh"
      '';
    };
    programs.skim = {
      enable = true;
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        directory = {
          truncate_to_repo = false;
          fish_style_pwd_dir_length = 1;
        };
        cmd_duration.disabled = true;
      };
    };
    # Enable XDG User Directories
    xdg.enable = true;

    # my favorite utils
    home.packages = with pkgs; [
      (
        writeScriptBin "print-zsh-colors" ''
          #!${bash}/bin/bash

          echo -e "|039| \033[39mDefault \033[m  |049| \033[49mDefault \033[m  |037| \033[37mLight gray \033[m     |047| \033[47mLight gray \033[m"
          echo -e "|030| \033[30mBlack \033[m    |040| \033[40mBlack \033[m    |090| \033[90mDark gray \033[m      |100| \033[100mDark gray \033[m"
          echo -e "|031| \033[31mRed \033[m      |041| \033[41mRed \033[m      |091| \033[91mLight red \033[m      |101| \033[101mLight red \033[m"
          echo -e "|032| \033[32mGreen \033[m    |042| \033[42mGreen \033[m    |092| \033[92mLight green \033[m    |102| \033[102mLight green \033[m"
          echo -e "|033| \033[33mYellow \033[m   |043| \033[43mYellow \033[m   |093| \033[93mLight yellow \033[m   |103| \033[103mLight yellow \033[m"
          echo -e "|034| \033[34mBlue \033[m     |044| \033[44mBlue \033[m     |094| \033[94mLight blue \033[m     |104| \033[104mLight blue \033[m"
          echo -e "|035| \033[35mMagenta \033[m  |045| \033[45mMagenta \033[m  |095| \033[95mLight magenta \033[m  |105| \033[105mLight magenta \033[m"
          echo -e "|036| \033[36mCyan \033[m     |046| \033[46mCyan \033[m     |096| \033[96mLight cyan \033[m     |106| \033[106mLight cyan \033[m"
        ''
      )
      (
        writeScriptBin "test-truecolors" ''
          #!${bash}/bin/bash
          # Based on: https://gist.github.com/XVilka/8346728

          awk -v term_cols="''${width:-$(tput cols || echo 80)}" 'BEGIN{
              s="/\\";
              for (colnum = 0; colnum<term_cols; colnum++) {
                  r = 255-(colnum*255/term_cols);
                  g = (colnum*510/term_cols);
                  b = (colnum*255/term_cols);
                  if (g>255) g = 510-g;
                  printf "\033[48;2;%d;%d;%dm", r,g,b;
                  printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
                  printf "%s\033[0m", substr(s,colnum%2+1,1);
              }
              printf "\n";
          }'
        ''
      )
      (
        writeScriptBin "rtfm" ''
          #!${bash}/bin/bash
          # source: https://gist.github.com/a1ip/12ae5bdd60ef882b3bfe158343a7fbac
          if [ "$#" -eq 0 ]; then
            while read  -p "Command: " cmd; do
              curl -Gs "https://www.mankier.com/api/v2/explain/?cols="$(tput cols) --data-urlencode "q=$cmd"
            done
            echo "Bye!"
          elif [ "$#" -eq 1 ]; then
            curl -Gs "https://www.mankier.com/api/v2/explain/?cols="$(tput cols) --data-urlencode "q=$1"
          else
            echo "Usage"
            echo "explain                  interactive mode."
            echo "explain 'cmd -o | ...'   one quoted command to explain it."
          fi
        ''
      )
      # curl
      curl
      # gnu awk
      gawk
      # colorizer
      grc
      # sed alt
      sd
      # tldr alt
      tealdeer
      # network bech util
      bandwhich
      # command line benchmark util - time alternativ
      hyperfine
      # grep alternative.
      ripgrep
      # ls alternative.
      exa
      # cat alternative.
      bat
      # nix stuff
      nix-zsh-completions
      # Simple, fast and user-friendly alternative to find.
      fd
      # More intuitive du.
      du-dust
      # cat for markdown
      mdcat
      # Visualize Nix gc-roots to delete to free space.
      nix-du
      # Keybase
      keybase
      # Show information about the current system
      neofetch
    ];

    home.sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };
  };
}
