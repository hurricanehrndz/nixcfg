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
        bind-key -T copy-mode-vi 'M-\' select-pane -l

        # smart splits resize
        bind-key -n C-M-h if -F "#{@pane-is-vim}" 'send-keys C-M-h' 'resize-pane -L 3'
        bind-key -n C-M-j if -F "#{@pane-is-vim}" 'send-keys C-M-j' 'resize-pane -D 3'
        bind-key -n C-M-k if -F "#{@pane-is-vim}" 'send-keys C-M-k' 'resize-pane -U 3'
        bind-key -n C-M-l if -F "#{@pane-is-vim}" 'send-keys C-M-l' 'resize-pane -R 3'

        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\\\'  'select-pane -l'"

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

        # Theme
        set -g @catppuccin_flavor 'latte'
        # Disable catppuccin styling windows.
        set -g @catppuccin_window_status_style "rounded"
        # leave this unset to let applications set the window title
        set -g @catppuccin_window_text " #W"
        set -g @catppuccin_window_current_text " #W"
        set -g @catppuccin_window_flags "icon"

        run ${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux

        set -g "@catppuccin_session_color" "#{E:@thm_green}"
        set -g status-right "#{E:@catppuccin_status_application}#{E:@catppuccin_status_session}#{E:@catppuccin_status_date_time}"
        set -g status-left "#[bg=#{@thm_surface_1},fg=#{@thm_fg}] #{=4:client_key_table} #[fg=#{@thm_teal},bg=#{@thm_bg}]█ "
        set -gu default-command
        set -g default-shell "$SHELL"
      '';
      plugins =
        with pkgs;
        with tmuxPlugins;
        [
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
