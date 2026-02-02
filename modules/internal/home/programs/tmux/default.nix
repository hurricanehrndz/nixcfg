{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  l = lib // builtins;
  cfg = osConfig.hrndz;
in
{
  config = l.mkIf cfg.tui.enable {
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      keyMode = "vi";
      terminal = "tmux-256color";
      aggressiveResize = true;
      escapeTime = 10;
      extraConfig = ''
        unbind C-b
        set-option -g prefix C-a
        bind-key C-a last-window
        bind-key -N "Send the prefix key through to the application" a send-prefix

        set -g set-clipboard on
        set -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY"
        set-option -sa terminal-overrides ',*256col*:RGB'
        set-option -g focus-events on
        bind r source-file $HOME/.config/tmux/tmux.conf \; display "TMUX conf reloaded!"
        bind k 'select-pane -U'
        bind j 'select-pane -D'
        bind h 'select-pane -L'
        bind l 'select-pane -R'

        # smart splits
        bind-key -n M-h if -F "#{@pane-is-vim}" 'send-keys M-h'  'select-pane -L'
        bind-key -n M-j if -F "#{@pane-is-vim}" 'send-keys M-j'  'select-pane -D'
        bind-key -n M-k if -F "#{@pane-is-vim}" 'send-keys M-k'  'select-pane -U'
        bind-key -n M-l if -F "#{@pane-is-vim}" 'send-keys M-l'  'select-pane -R'
        bind-key -T copy-mode-vi 'M-h' select-pane -L
        bind-key -T copy-mode-vi 'M-j' select-pane -D
        bind-key -T copy-mode-vi 'M-k' select-pane -U
        bind-key -T copy-mode-vi 'M-l' select-pane -R
        bind-key -T copy-mode-vi 'M-;' select-pane -l

        # smart splits resize
        # bind -n M-H resize-pane -L 5
        # bind -n M-J resize-pane -D 5
        # bind -n M-K resize-pane -U 5
        # bind -n M-L resize-pane -R 5
        bind-key -n M-H if -F "#{@pane-is-vim}" 'send-keys M-H' 'resize-pane -L 3'
        bind-key -n M-J if -F "#{@pane-is-vim}" 'send-keys M-J' 'resize-pane -D 3'
        bind-key -n M-K if -F "#{@pane-is-vim}" 'send-keys M-K' 'resize-pane -U 3'
        bind-key -n M-L if -F "#{@pane-is-vim}" 'send-keys M-L' 'resize-pane -R 3'

        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'A-;' if -F \"#{@pane-is-vim}\" 'send-keys A-;'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'A-;' if -F \"#{@pane-is-vim}\" 'send-keys A-;'  'select-pane -l'"

        bind-key Z switch-client -T size

        bind-key -T size k resize-pane -U 3 \; switch-client -T size
        bind-key -T size j resize-pane -D 3 \; switch-client -T size
        bind-key -T size h resize-pane -L 3 \; switch-client -T size
        bind-key -T size l resize-pane -R 3 \; switch-client -T size

        bind-key -T size K resize-pane -U 5 \; switch-client -T size
        bind-key -T size J resize-pane -D 5 \; switch-client -T size
        bind-key -T size H resize-pane -L 5 \; switch-client -T size
        bind-key -T size L resize-pane -R 5 \; switch-client -T size

        # begin selection with v, yank with y
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # fix clear screen
        bind C-l send-keys 'C-l'

        # easily rotate window
        bind-key -n 'M-o' rotate-window

        # same directory
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # easily zoom
        bind-key -n 'M-z' resize-pane -Z

        set -gu default-command
        set -g default-shell "$SHELL"
      '';
      plugins =
        with pkgs;
        with tmuxPlugins;
        [
          {
            plugin = catppuccin;
            extraConfig = ''
              # Theme
              set -g @catppuccin_flavor 'latte'
              set -g @catppuccin_window_status_style "rounded"
              set -g @catppuccin_window_text " #W"
              set -g @catppuccin_window_current_text " #W"
              set -g @catppuccin_window_flags "icon"

              # Right status
              set -g @catppuccin_session_color "#{E:@thm_green}"
              set -g status-right "#{E:@catppuccin_status_application}#{E:@catppuccin_status_session}#{E:@catppuccin_status_date_time}"

              # Left status
              # are we controlling tmux or the content of the panes?
              set -g status-left "#[bg=#{@thm_surface_0}]#[fg=#{@thm_text}]#{?client_prefix,#[bg=#{@thm_green}],}"
              if-shell '[[ $(uname) = Darwin ]]' \
                'set -ga status-left "  "' \
                'set -ga status-left "  "'

              # window style
              set -g window-style "fg=#{@thm_overlay_1},bg=#{@thm_mantle},dim"
              set -g window-active-style "fg=#{@thm_fg},bg=default"
            '';
          }
          {
            plugin = extrakto;
            extraConfig = ''
              set -g @extrakto_clip_tool_run "tmux_osc52"
              set -g @extrakto_clip_tool "tmux_osc52"
              set -g @extrakto_popup_size "65%"
              set -g @extrakto_grab_area "window 500"
            '';
          }
        ];
    };
  };
}
