{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  l = lib // builtins;
  cfg = osConfig.hrndz;
  c = config.lib.stylix.colors.withHashtag;

  # A block-edged status module: coloured icon cell, then a text cell.
  module =
    color: icon: text:
    "#[fg=${color}]█#[fg=${c.base00},bg=${color}]${icon}#[fg=${c.base05},bg=${c.base01}] ${text}#[fg=${c.base01}]█";

  flags = l.concatStrings [
    "#{?window_activity_flag, 󱅫,}"
    "#{?window_bell_flag, 󰂞,}"
    "#{?window_silence_flag, 󰂛,}"
    "#{?window_active, 󰖯,}"
    "#{?window_last_flag, 󰖰,}"
    "#{?window_marked_flag, 󰃀,}"
    "#{?window_zoomed_flag, 󰁌,} "
  ];
  window =
    numberBg: textBg: "#[fg=${c.base00},bg=${numberBg}] #I #[fg=${c.base05},bg=${textBg}] #W${flags}";
in
{
  config = l.mkIf cfg.roles.terminalUser.enable {
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      keyMode = "vi";
      terminal = "tmux-256color";
      aggressiveResize = true;
      escapeTime = 10;
      mouse = true;
      historyLimit = 50000;
      extraConfig = ''
        unbind C-b
        set-option -g prefix C-a
        bind-key C-a last-window
        bind-key -N "Send the prefix key through to the application" a send-prefix

        set -g set-clipboard on
        set -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY"
        set -g focus-events on
        set -g allow-passthrough on
        set -g extended-keys on
        set -g extended-keys-format csi-u
        set -sa terminal-overrides ',*256col*:RGB'
        bind r source-file $HOME/.config/tmux/tmux.conf \; display "TMUX conf reloaded!"
        bind k 'select-pane -U'
        bind j 'select-pane -D'
        bind h 'select-pane -L'
        bind l 'select-pane -R'

        # Option+hjkl is left unbound so it passes through to the app (e.g. vim
        # window navigation). Use the prefix h/j/k/l bindings above to move
        # between tmux panes.
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

        ##: Theme (colours from hrndz.theme.scheme via Stylix)
        set -g status-style "bg=${c.base00},fg=${c.base05}"
        set -g status-left-length 100
        set -g status-right-length 100
        set -g message-style "fg=${c.base0C},bg=${c.base01},align=centre"
        set -g message-command-style "fg=${c.base0C},bg=${c.base01},align=centre"
        set -g mode-style "bg=${c.base01},bold"
        set -g menu-selected-style "fg=${c.base05},bold,bg=${c.base02}"
        set -g popup-style "bg=${c.base00},fg=${c.base05}"
        set -g popup-border-style "fg=${c.base02}"
        set -g clock-mode-colour "${c.base0D}"
        set -g pane-border-style "fg=${c.base03}"
        set -g pane-active-border-style "#{?pane_synchronized,fg=${c.base0E},fg=${c.base0D}}"

        # Inactive panes defer to ghostty's background too (keep `dim` + a
        # muted fg as the only inactive cue); active stays transparent.
        set -g window-style "fg=${c.base03},bg=default,dim"
        set -g window-active-style "fg=${c.base05},bg=default"

        set -g window-status-format "${window c.base03 c.base01}"
        set -g window-status-current-format "${window c.base0E c.base02}"
        set -g window-status-activity-style "bg=${c.base0D},fg=${c.base00}"
        set -g window-status-bell-style "bg=${c.base0A},fg=${c.base00}"

        # Left status: the OS block turns red while the prefix is held; the
        # session block stays a steady colour.
        set -g status-left "#[bg=${c.base01},fg=${c.base05}]#{?client_prefix,#[bg=${c.base08}],}"
        if-shell '[[ $(uname) = Darwin ]]' \
          'set -ga status-left "  "' \
          'set -ga status-left "  "'
        set -ga status-left "${module c.base0B " " "#S"}"
        set -ga status-left "#[fg=default,bg=${c.base00}] "

        # Right status. The host block is appended only when the client is
        # attached over SSH: SSH_CONNECTION is refreshed in the session
        # environment on every attach via update-environment (see above), so
        # the hostname (just left of the clock) shows on remote sessions and
        # stays hidden locally. Modules live in options so their commas don't
        # split the conditional.
        set -g @status_application "${module c.base08 " " "#{pane_current_command}"}"
        set -g @status_host "${module c.base0E "󰒋 " "#H"}"
        set -g @status_date_time "${module c.base0C "󰃰 " "%Y-%m-%d %H:%M"}"
        set -g status-right "#{E:@status_application}#{?SSH_CONNECTION,#{E:@status_host},}#{E:@status_date_time}"
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
          {
            plugin = fingers;
            extraConfig = ''
              unbind-key Space
              set -g @fingers-key Space
            '';
          }
        ];
    };
  };
}
