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
          src = pkgs.fetchFromGitHub {
            owner = "romkatv";
            repo = "zsh-defer";
            rev = "master";
            sha256 = "sha256-zMvVY2FojwuTXH+NFoUv7+b9zD1wsmB5D16EvXsk7vY";
          };
        }
        {
          # https://github.com/starship/starship/issues/1721#issuecomment-780250578
          # stop eating lines this is not pacman
          name = "zsh-vi-mode";
          file = "zsh-vi-mode.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "jeffreytse";
            repo = "zsh-vi-mode";
            rev = "master";
            sha256 = "sha256-+37toh6SBNSpn9tXRbJIbFINKKWuaGHM2PZQ2+DbpAg";
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
        # Nix setup (environment variables, etc.)
        [[ -e ~/.nix-profile/bin ]] && path=("$HOME/.nix-profile/bin" $path)
        if [[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] \
            && [[ -z "$NIX_SSL_CERT_FILE" ]]; then
          source ~/.nix-profile/etc/profile.d/nix.sh
        fi

        # XDG bin
        path=("$HOME/.local/bin" $path)

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
        # tmux
        "tm" = "${tmux}/bin/tmux new-session -A -s main";
        # general
        "mkdir" = "mkdir -p";
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
      (writeScriptBin "yank" (builtins.readFile ./yank))
      # top alternativ
      bottom
      # fuzzy finder
      skim
      fzf
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
    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      customPaneNavigationAndResize = false;
      keyMode = "vi";
      newSession = false;
      shortcut = "a";
      terminal = "screen-256color";
      resizeAmount = 10;
      historyLimit = 10000;
      plugins = with pkgs; [
        tmuxPlugins.copycat
        tmuxPlugins.jump
        {
          plugin = tmuxPlugins.extrakto;
          extraConfig = ''
            set -g set-clipboard on

            set -g @extrakto_clip_tool_run "fg"
            set -g @extrakto_clip_tool "yank"
            set -g @extrakto_copy_key "y"
            set -g @extrakto_insert_key "enter"
            set -g @extrakto_popup_size "65%"
            set -g @extrakto_grab_area "window 500"
          '';
        }
      ];
      extraConfig = with lib; ''
        # Reload tmux.conf
        bind r source-file ~/.config/tmux/tmux.conf \; display "TMUX conf reloaded!"

        # begin selection with v, yank with y
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel yank

        # Smart pane switching with awareness of Vim splits.
        # See: https://github.com/christoomey/vim-tmux-navigator
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
            | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        bind-key -n 'M-h' if-shell "$is_vim" 'send-keys M-h'  'select-pane -L'
        bind-key -n 'M-j' if-shell "$is_vim" 'send-keys M-j'  'select-pane -D'
        bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k'  'select-pane -U'
        bind-key -n 'M-l' if-shell "$is_vim" 'send-keys M-l'  'select-pane -R'

        bind-key -T copy-mode-vi 'M-h' select-pane -L
        bind-key -T copy-mode-vi 'M-j' select-pane -D
        bind-key -T copy-mode-vi 'M-k' select-pane -U
        bind-key -T copy-mode-vi 'M-l' select-pane -R

        # easily rotate window
        bind-key -n 'M-o' rotate-window

        # easily zoom
        bind-key -n 'M-z' resize-pane -Z

        # neovim recommendations - checkhealth
        set-option -sg escape-time 0
        set-option -g focus-events on
        #set -g default-terminal 'tmux-256color'
        set -sa terminal-overrides ',xterm*:RGB'

        # resize panes more easily
        bind < resize-pane -L ${toString config.programs.tmux.resizeAmount}
        bind > resize-pane -R ${toString config.programs.tmux.resizeAmount}
        bind - resize-pane -D ${toString config.programs.tmux.resizeAmount}
        bind + resize-pane -U ${toString config.programs.tmux.resizeAmount}
        bind -r H resize-pane -L ${toString config.programs.tmux.resizeAmount}
        bind -r J resize-pane -D ${toString config.programs.tmux.resizeAmount}
        bind -r K resize-pane -U ${toString config.programs.tmux.resizeAmount}
        bind -r L resize-pane -R ${toString config.programs.tmux.resizeAmount}

        # toggle status bar
        bind-key ^s { set-option status }

        # update environment
        set-option -g update-environment "SSH_AUTH_SOCK \
                                          SSH_CONNECTION \
                                          DISPLAY"

        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        # bind c new-window -c "#{pane_current_path}"

        # theme - pane border
        # https://cassidy.codes/blog/2019-08-03-tmux-colour-theme/
        set -g pane-border-style fg='#5ccfe6'
        set -g pane-active-border-style fg='#ff3333'
        # theme - message text
        set -g message-style bg='#191e2a',fg='#5ccfe6'
        # theme - status line
        set -g status-style bg='#191e2a',fg='#707a8c'
        set -g status-interval 5

        # theme - current window
        set -g window-status-current-format "#[fg=#191e2a]#[bg=#ff3333] #I:#W "
        set -g window-status-format "#[fg=#8A9199]#[bg=#191e2a] #I:#W "

        # status left
        # are we controlling tmux or the content of the panes?
        set -g status-left '#[bg=#cbccc6]#[fg=#101521]#{?client_prefix,#[bg=#bae67E],}  '
        # are we zoomed into a pane?
        set -ga status-left '#[bg=#191e2a]#[fg=#bae67E]#{?window_zoomed_flag, ↕ ,   }'
      '';
    };
  };
}
