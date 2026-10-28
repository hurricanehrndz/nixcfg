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
    add-zsh-hook preexec _update_ssh_agent
fi

# Append gitignore.io templates to the repo's .gitignore; no args opens a picker.
gi() {
    local api="https://www.toptal.com/developers/gitignore/api"
    local -a templates=("$@")
    if ((!$#templates)); then
        templates=(${(f)"$(curl -fsSL "$api/list?format=lines" |
            fzf -m --preview "curl -fsSL $api/{}")"})
    fi
    (($#templates)) || return 1
    local file="$(git rev-parse --show-toplevel 2>/dev/null || print -r -- "$PWD")/.gitignore"
    local body
    body="$(curl -fsSL "$api/${(j:,:)templates}")" || return
    print -r -- "$body" >>"$file" && print -r -- "updated $file"
}

batman() {
    BAT_THEME='Catppuccin Latte' command batman "$@"
    return $?
}

# completions
compdef _files cpv
compdef _bat cat
compdef _files v
