# vim:set ft=sh:
# shellcheck shell=bash disable=SC2148,SC2154,SC2034,SC2086,SC2296,SC1090,SC1091,SC2140
# aliases

if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
    alias vi="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
    alias v="nvr -s -cc 'LazygitCloseFocusLargest' &&  nvr "
fi
alias gitlint="gitlint --contrib=CT1 --ignore body-is-missing,T3 -c T1.line-length=50 -c B1.line-length=72"

#######################################
#  Git aliases
#  Below are aliases from plugins:
#    ga=forgit::add
#    gat=forgit::attributes
#    gbd=forgit::branch::delete
#    gbl=forgit::blame
#    gcb=forgit::checkout::branch
#    gcf=forgit::checkout::file
#    gclean=forgit::clean
#    gco=forgit::checkout::commit
#    gcp=forgit::cherry::pick::from::branch
#    gct=forgit::checkout::tag
#    gd=forgit::diff
#    gfu=forgit::fixup
#    gi=forgit::ignore
#    gitlint='gitlint --contrib=CT1 --ignore body-is-missing,T3 -c T1.line-length=50 -c B1.line-length=72'
#    glo=forgit::log
#    grb=forgit::rebase
#    grc=forgit::revert::commit
#    grep='grep --color=auto'
#    grh=forgit::reset::head
#    grl=forgit::reflog
#    grw=forgit::reword
#    gso=forgit::show
#    gsp=forgit::stash::push
#    gsq=forgit::squash
#    gss=forgit::stash::show
#    gsw=forgit::switch::branch
#
#######################################
alias g=git
alias gaa='git add --all'
alias gc='git commit --verbose'                \
      gcs='git commit --verbose --sign'        \
      gca='git commit --verbose --amend'       \
      gcaa='git commit --verbose --amend --all'

alias gdc='gd --cached'

alias gcm='git checkout main'

alias gst='git status' \
      gss='git status --short'

# forgit stash redefined
alias gsv=forgit::stash::show

alias grh='git reset' \
      grhh='git reset --hard' \
      grv=forgit::reset::head

alias gf='git fetch'   \
      gfm='git pull'    # a pull, is a fetch and merge

alias gp='git push'                     \
      gpf='git push --force'            \
      gpF='git push --force-with-lease' \
      gpc='git push --set-upstream origin HEAD'

# git clone
alias gcl='git clone'

# git branch
alias gb='git branch' \
      gba='git branch -a'

# git merge
alias gm='git merge'

# git show
alias gsh='git show'

# git stash
alias gsta='git stash'

# Git rebase sign commits
alias grsc='git rebase --exec "git commit --amend --no-edit -n -S" -i'

# git log
_git_log_oneline_format='%C(green)%h%C(reset) %s%C(red)%d %C(reset)%C(blue)Sig:%G?%C(reset)%n'
_git_log_brief_format='%C(green)%h%C(reset) %s%n%C(blue)(%ar by %an)%C(red)%d%C(reset)%n'

_git_log_medium_format='%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n'
_git_log_medium_format+='%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n'
_git_log_medium_format+='%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B'
alias gl='git log --topo-order --pretty=format:"$_git_log_medium_format"' \
      glb='git log --topo-order --pretty=format:"$_git_log_brief_format"' \
      glg='git log --topo-order --all --graph --pretty=format:"${_git_log_oneline_format}"'

#######################################
# ls alternatives
#######################################
alias ls='eza --group-directories-first'
alias ll='eza --group-directories-first -l --git'
alias la='eza --group-directories-first -l --git -a'
alias l='eza --group-directories-first -l --git -a'
alias lt='eza --group-directories-first -l --git -smodified'      # Long format, newest modification time last
alias lx='eza --group-directories-first -l --git -sextension'     # Long format, sort by extension
alias lk='eza --group-directories-first -l --git -ssize'          # Long format, largest file size last
alias lc='eza --group-directories-first -l --git -schanged'       # Long format, newest status change (ctime) last

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
alias clauded='claude --dangerously-skip-permissions'
