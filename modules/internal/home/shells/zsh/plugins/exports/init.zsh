# vim:set ft=sh:
# shellcheck shell=bash disable=SC2148,SC2154,SC2034,SC2086,SC2296,SC1090,SC1091,SC2140
# exports

if [[ "$TERM_PROGRAM" == "vscode" ]]; then
	export VISUAL="code --wait"
	export EDITOR="code --wait"
elif [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
    export EDITOR="nvr -s -cc '"LazygitCloseFocusLargest"' &&  nvr "
    export VISUAL="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
else
    export EDITOR="v"
    export VISUAL="v"
fi

export EZA_COLORS='da=1;34:gm=1;34:Su=1;34'
export BAT_CONFIG_FILE="$HOME/.config/bat/config"

#######################################
# batman settings
#######################################
export MANPAGER=" BATMAN_IS_BEING_MANPAGER=yes BAT_THEME='Monokai Extended Light' command batman"
export MANROFFOPT=-c

# Async mode for autocompletion
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_MAXLENGTH=100
