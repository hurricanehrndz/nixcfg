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
          name = "zsh-utils";
          file = "directory.plugin.zsh";
          src = ./zsh-utils;
        }
        {
          name = "zsh-utils";
          file = "editor.plugin.zsh";
          src = ./zsh-utils;
        }
        {
          name = "zsh-utils";
          file = "history.plugin.zsh";
          src = ./zsh-utils;
        }
        {
          name = "zsh-utils";
          file = "completion.plugin.zsh";
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
          src = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search";
        }
        {
          name = "zsh-autosuggestions";
          file = "zsh-autosuggestions.zsh";
          src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
          apply = "zsh-defer";
        }
      ];
    };

    # Enable shell management
    programs.zsh = {
      enable = true;
     # autocd = true;
      enableCompletion = false; # Enable when ready
      #defaultKeymap = "viins";
      dotDir = ".config/zsh";
      history = {
        extended = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        path =  "${config.xdg.configHome}/zsh/zsh_history";
      };

      initExtra = ''
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
        "l"  = "${exa}/bin/exa -1 --group-directories-first -F";
        "tree" = "${exa}/bin/exa -T";
        # Aliases for `cat` to `bat`.
        "cat" = "${bat}/bin/bat";
      };
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
      (writeScriptBin "print-colors" (builtins.readFile ./print-colors))
      (writeScriptBin "test-truecolors" (builtins.readFile ./test-truecolors))
      (writeScriptBin "rtfm" (builtins.readFile ./rtfm))
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
