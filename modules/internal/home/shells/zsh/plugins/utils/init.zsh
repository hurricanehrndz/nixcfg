# vim:set ft=sh:
# shellcheck shell=bash disable=SC2148,SC2154,SC2034,SC2086,SC2296,SC1090,SC1091
cpv() {
    rsync -pogbr -hhh --backup-dir="/tmp/rsync-''${USERNAME}" -e /dev/null --progress "$@"
}

# Cross platform `sed -i` syntax.
function sedi {
    # GNU/BSD
    if sed --version &>/dev/null; then
        sed -i -- "$@"
    else
        sed -i "" "$@"
    fi
}

_update_ssh_agent() {
    if ! [[ -S $SSH_AUTH_SOCK ]]; then
        eval "$(tmux show-environment -s SSH_AUTH_SOCK 2>/dev/null)"
    fi
}
autoload -Uz add-zsh-hook
if [[ -n "$TMUX" ]]; then
    add-zsh-hook precmd _update_ssh_agent
fi

batman() {
    BAT_THEME='Monokai Extended Light' command batman "$@"
    return $?
}

# completions
compdef _files cpv
compdef what-would-happen-on=ssh wwho=ssh
compdef _chezmoi cm
compdef _bat cat
compdef _files v
