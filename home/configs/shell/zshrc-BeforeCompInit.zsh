# XDG bin
path=("$HOME/.local/bin" $path)
[[ -e ~/.nix-profile/bin ]] && path=("$HOME/.nix-profile/bin" $path)

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

ZVM_CURSOR_STYLE_ENABLED=false
