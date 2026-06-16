# vim:set ft=sh:
# shellcheck shell=bash disable=SC2148,SC2154,SC2034,SC2086,SC2296,SC1090,SC1091,SC2140
# aliases

if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
    alias vi="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
    alias v="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
fi
alias gitlint="gitlint --contrib=CT1 --ignore body-is-missing,T3 -c T1.line-length=50 -c B1.line-length=72"

#######################################
# Git shortcuts live in git config and are invoked as `g <alias>`.
#######################################
alias g=git

#######################################
# ls alternatives
#######################################
alias ls='eza --group-directories-first'
alias ll='eza --group-directories-first -l -h -g --git'
alias la='eza --group-directories-first -l -h -g --git -a'
alias l='eza --group-directories-first -l -h -g --git -a'
alias lt='eza --group-directories-first -l -h -g --git -smodified'      # Long format, newest modification time last
alias lx='eza --group-directories-first -l -h -g --git -sextension'     # Long format, sort by extension
alias lk='eza --group-directories-first -l -h -g --git -ssize'          # Long format, largest file size last
alias lc='eza --group-directories-first -l -h -g --git -schanged'       # Long format, newest status change (ctime) last

#######################################
# cat alternative
#######################################
alias rcat=cat
alias cat=bat

#######################################
# tmux aliases
#######################################
alias tm='tmux new-session -A -s main'
alias tl='tmux list-sessions'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'

#######################################
# utility aliases
#######################################
alias xsh='TERM=xterm-256color ssh'
alias devbox='xsh dev'
alias vi='v'
alias lg='lazygit'
alias mkdir='mkdir -p'
alias path='echo $PATH | tr ":" "\n"'
alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h'
alias vimdiff='v -d'
alias rg='rg -i -L'
alias rgv="rg --line-number --with-filename --color=always --field-match-separator ' ' . |
  fzf --ansi --delimiter ' ' \
    --preview 'bat --color=always --highlight-line {2} {1}' \
    --preview-window 'right,50%,+{2}-3,~3'"
alias mdcat='glow'
alias clauded='claude --dangerously-skip-permissions'
alias pi='env -u AWS_PROFILE pi'
