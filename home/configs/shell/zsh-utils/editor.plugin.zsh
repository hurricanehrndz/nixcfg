#
# Requirements
#

# Return if requirements are not found.
if [[ "$TERM" == 'dumb' ]]; then
  return 1
fi

#
# Options
#

setopt BEEP                     # Beep on error in line editor.
unsetopt FLOW_CONTROL           # Allow the usage of ^Q/^S in the context of zsh.

#
# Variables
#

# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

# Use human-friendly identifiers.
zmodload zsh/terminfo
typeset -gA key_info

# Modifiers
key_info=(
  'Control'      '\C-'
  'Escape'       '\e'
  'Meta'         '\M-'
)

# Basic keys
key_info+=(
  'Backspace'    "^?"
  'Delete'       "^[[3~"
  'F1'           "$terminfo[kf1]"
  'F2'           "$terminfo[kf2]"
  'F3'           "$terminfo[kf3]"
  'F4'           "$terminfo[kf4]"
  'F5'           "$terminfo[kf5]"
  'F6'           "$terminfo[kf6]"
  'F7'           "$terminfo[kf7]"
  'F8'           "$terminfo[kf8]"
  'F9'           "$terminfo[kf9]"
  'F10'          "$terminfo[kf10]"
  'F11'          "$terminfo[kf11]"
  'F12'          "$terminfo[kf12]"
  'Insert'       "$terminfo[kich1]"
  'Home'         "$terminfo[khome]"
  'PageUp'       "$terminfo[kpp]"
  'End'          "$terminfo[kend]"
  'PageDown'     "$terminfo[knp]"
  'Up'           "$terminfo[kcuu1]"
  'Left'         "$terminfo[kcub1]"
  'Down'         "$terminfo[kcud1]"
  'Right'        "$terminfo[kcuf1]"
  'BackTab'      "$terminfo[kcbt]"
)

# Mod plus another key
key_info+=(
  'AltLeft'         "${key_info[Escape]}${key_info[Left]} \e[1;3D"
  'AltRight'        "${key_info[Escape]}${key_info[Right]} \e[1;3C"
  'ControlLeft'     '\e[1;5D \e[5D \e\e[D \eOd'
  'ControlRight'    '\e[1;5C \e[5C \e\e[C \eOc'
  'ControlPageUp'   '\e[5;5~'
  'ControlPageDown' '\e[6;5~'
)

#
# Functions
#

function is-term-family {
  if [[ $TERM = $1 || $TERM = $1-* ]]; then
    return 0
  fi

  return 1
}

function is-tmux {
  if is-term-family tmux; then
    return 0
  fi

  if [[ -n "$TMUX" ]]; then
    return 0
  fi

  return 1
}

function update-cursor-style {
  # We currently only support the xterm family of terminals
  if ! is-term-family xterm && ! is-term-family rxvt && ! is-tmux; then
    return
  fi

  if bindkey -lL main | grep viins > /dev/null; then
    # For vi-mode we
    case $KEYMAP in
      vicmd)      printf '\e[2 q';;
      viins|main) printf '\e[6 q';;
    esac
  else
    # If we're in emacs mode, we always want the block cursor
    printf '\e[2 q'
  fi
}
zle -N update-cursor-style

# Enables terminal application mode
function zle-line-init {
  # The terminal must be in application mode when ZLE is active for $terminfo
  # values to be valid.
  if (( $+terminfo[smkx] )); then
    # Enable terminal application mode.
    echoti smkx
  fi

  # Ensure we have the correct cursor. We could probably do this less
  # frequently, but this does what we need and shouldn't incur that much
  # overhead.
  zle update-cursor-style
}
zle -N zle-line-init

# Disables terminal application mode
function zle-line-finish {
  # The terminal must be in application mode when ZLE is active for $terminfo
  # values to be valid.
  if (( $+terminfo[rmkx] )); then
    # Disable terminal application mode.
    echoti rmkx
  fi
}
zle -N zle-line-finish

# Resets the prompt when the keymap changes
function zle-keymap-select {
  zle update-cursor-style

  zle reset-prompt
  zle -R
}
zle -N zle-keymap-select

#
# Init
#

# Reset to default key bindings
bindkey -d

#
# Keybinds
#

# Global keybinds
local -A global_keybinds
global_keybinds=(
  "$key_info[Home]"   beginning-of-line
  "$key_info[End]"    end-of-line
  "$key_info[Delete]" delete-char
)

# emacs and vi insert mode keybinds
local -A viins_keybinds
viins_keybinds=(
  "$key_info[Backspace]" backward-delete-char
  "$key_info[Control]W"  backward-kill-word
)

# vi command mode keybinds
local -A vicmd_keybinds
vicmd_keybinds=(
  "$key_info[Delete]" delete-char
)

# Special case for ControlLeft and ControlRight because they have multiple
# possible binds.
for key in "${(s: :)key_info[ControlLeft]}" "${(s: :)key_info[AltLeft]}"; do
  bindkey -M viins "$key" vi-backward-word
  bindkey -M vicmd "$key" vi-backward-word
done
for key in "${(s: :)key_info[ControlRight]}" "${(s: :)key_info[AltRight]}"; do
  bindkey -M viins "$key" vi-forward-word
  bindkey -M vicmd "$key" vi-forward-word
done

# Bind all global, vi, and viins keys to the viins keymap
for key bind in ${(kv)global_keybinds} ${(kv)viins_keybinds}; do
  bindkey -M viins "$key" "$bind"
done

# Bind all global, vi, and vicmd keys to the vicmd keymap
for key bind in ${(kv)global_keybinds} ${(kv)vicmd_keybinds}; do
  bindkey -M vicmd "$key" "$bind"
done

# Edit command in an external editor emacs style (v is used for visual mode)
bindkey -M vicmd "$key_info[Control]X$key_info[Control]E" edit-command-line
bindkey -M viins "$key_info[Control]X$key_info[Control]E" edit-command-line

# Undo/Redo
bindkey -M vicmd "u" undo
bindkey -M vicmd "$key_info[Control]R" redo

# Toggle comment at the start of the line.
bindkey -M vicmd "#" vi-pound-insert

# Inserts 'sudo ' at the beginning of the line.
function prepend-sudo {
  if [[ "$BUFFER" != su(do|)\ * ]]; then
    BUFFER="sudo $BUFFER"
    (( CURSOR += 5 ))
  fi
}
zle -N prepend-sudo
# Insert 'sudo ' at the beginning of the line.
bindkey -M viins "$key_info[Control]X$key_info[Control]S" prepend-sudo

# Plugins key binds
bindkey   -M   viins   "$key_info[Control]K"   history-substring-search-up
bindkey   -M   viins   "$key_info[Control]J"   history-substring-search-down
bindkey   -M   viins   "$key_info[Control]Y"   autosuggest-accept
bindkey   -M   vicmd   "k"                     history-substring-search-up
bindkey   -M   vicmd   "j"                     history-substring-search-down

bindkey -v
