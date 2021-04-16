{ config, lib, pkgs, ... }:

with lib;
let cfg = config.hurricane.configs.shell;
in {
  options.hurricane = {
    configs.shell.enable = mkEnableOption "enable awsome zsh config";
  };
  config = mkIf cfg.enable {
    hurricane.configs.zplugins = {
      enable = true;
      plugins = [
        {
          name = "zsh-defer";
          file = "zsh-defer.plugin.zsh";
          src = builtins.fetchGit {
            url = "https://github.com/romkatv/zsh-defer";
            rev = "9d47fc2c51ec59e19ad41aa36f018ca8b851cf66";
          };
        }
        {
          # https://github.com/starship/starship/issues/1721#issuecomment-780250578
          # stop eating lines this is not pacman
          name = "zsh-vi-mode";
          file = "zsh-vi-mode.plugin.zsh";
          src = builtins.fetchGit {
            url = "https://github.com/jeffreytse/zsh-vi-mode";
            rev = "2cdeb68d5eab63a8bd951aec52bb407b8445fb1a";
          };
        }
        {
          name = "zsh-utils";
          file = "history.plugin.zsh";
          src = ./zsh-utils;
        }
        {
          name = "zsh-utils";
          file = "directory.plugin.zsh";
          src = ./zsh-utils;
        }
        {
          name = "fast-syntax-highlighting";
          file = "fast-syntax-highlighting.plugin.zsh";
          src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
          apply = "zsh-defer";
        }
        {
          name = "zsh-history-substring-search";
          file = "zsh-history-substring-search.zsh";
          src =
            "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search";
        }
        {
          name = "zsh-autosuggestions";
          file = "zsh-autosuggestions.zsh";
          src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
          apply = "zsh-defer";
        }
        {
          name = "zsh-utils";
          file = "completion.plugin.zsh";
          src = ./zsh-utils;
        }
      ];
    };

    # Enable shell management
    programs.zsh = {
      enable = true;
      # autocd = true;
      enableCompletion = false; # Enable when ready
      dotDir = ".config/zsh";
      history = {
        extended = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        path = "${config.xdg.configHome}/zsh/zsh_history";
      };
      initExtraBeforeCompInit = ''
        # XDG bin
        path=("$HOME/.local/bin" $path)

        # Nix setup (environment variables, etc.)
        if [[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] \
            && [[ -z "$NIX_SSL_CERT_FILE" ]]; then
          source ~/.nix-profile/etc/profile.d/nix.sh
        fi

        # Load environment variables from a file; this approach allows me to not
        # commit secrets like API keys to Git
        if [ -e ~/.env ]; then
          source ~/.env
        fi

        # Inserts 'sudo ' at the beginning of the line.
        function prepend_sudo {
          if [[ "$BUFFER" != su(do|)\ * ]]; then
            BUFFER="sudo $BUFFER"
            (( CURSOR += 5 ))
          fi
        }
        zle -N prepend_sudo

        autoload -U edit-command-line
        zle -N edit-command-line

        # Define an init function and append to zvm_after_init_commands
        function zvm_after_init() {
          source ${pkgs.skim}/share/skim/completion.zsh
          source ${pkgs.skim}/share/skim/key-bindings.zsh

          # my key bindings
          bindkey   -M   viins   '\C-X\C-S'      prepend_sudo
          bindkey   -M   viins   '\C-Y'          autosuggest-accept
          bindkey   -M   viins   '\C-K'          history-substring-search-up
          bindkey   -M   viins   '\C-J'          history-substring-search-down
          bindkey   -M   vicmd   'k'             history-substring-search-up
          bindkey   -M   vicmd   'j'             history-substring-search-down
          bindkey   -M   vicmd   '\C-X\C-E'      edit-command-line
          bindkey   -M   viins   '\C-X\C-E'      edit-command-line
        }
      '';
      initExtra = ''
        ZVM_CURSOR_STYLE_ENABLED=false
      '';
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
        "l" = "${exa}/bin/exa -1 --group-directories-first -F";
        "tree" = "${exa}/bin/exa -T";
        # Aliases for `cat` to `bat`.
        "cat" = "${bat}/bin/bat";
      };
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
        aws.disabled = true;
        scan_timeout = 10;
      };
    };
    # Enable XDG User Directories
    xdg.enable = true;

    # my favorite utils
    home.packages = with pkgs; [
      (writeScriptBin "print-colors" (builtins.readFile ./print-colors))
      (writeScriptBin "test-truecolors" (builtins.readFile ./test-truecolors))
      (writeScriptBin "rtfm" (builtins.readFile ./rtfm))
      # fuzzy finder
      skim
      # curl
      curl
      # gnu awk
      gawk
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
      nix-zsh-completions
      zsh-completions
    ];

    home.sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BAT_THEME = "TwoDark";
    };
    programs.bat = {
      enable = true;
      config = {
        theme = config.home.sessionVariables.BAT_THEME;
        pager = "less -FR";
      };
    };
  };
}
