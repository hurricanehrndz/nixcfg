{ config, lib, ... }:

with lib;

{
  tmuxConf = ''
    # Reload tmux.conf
    bind r source-file ~/.config/tmux/tmux.conf \; display "TMUX conf reloaded!"

    # begin selection with v, yank with y
    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel yank

    # Smart pane switching with awareness of Vim splits.
    # See: https://github.com/christoomey/vim-tmux-navigator
    is_vim="ps -o state=,tty=,comm= | grep -iqE '^[^TXZ ]+ +#{s|/dev/||:pane_tty}\s+(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
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

    # tmux popup
    # TODO: need to kill popup session when parent session dies
    bind-key e run-shell 'tmux-popup'
    # clean popups
    set-hook -g pane-died "run-shell 'tmux-cleanup'"
    set-hook -g pane-exited "run-shell 'tmux-cleanup'"
    set-hook -g after-kill-pane "run-shell 'tmux-cleanup'"

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
}
