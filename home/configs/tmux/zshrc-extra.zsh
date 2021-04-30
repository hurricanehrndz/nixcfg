if [[ -n "$TMUX" ]]; then
  tmux_session="$(tmux display-message -p -F "#{session_name}")"
  if [[ ! "$tmux_session" =~ "popup" ]]; then
    WINDOW_ID=$(tmux display -p "#{window_id}")
    export NVIM_LISTEN_ADDRESS="/tmp/nvim_''${USER}_''${WINDOW_ID}"
  fi
  # special zfunction to open vim in parent window
  if [[ "$tmux_session" =~ "popup" ]]; then
    export EDITOR='tvi'
    alias nvim='tvi'
    alias vi='tvi'
  fi
fi
