# extended vim bindings
bindkey   -M   viins   '^Y'      autosuggest-accept
bindkey   -M   viins   '^P'      history-search-backward
bindkey   -M   viins   '^N'      history-search-forward
# <Ctrl-x><Ctrl-e> to edit command-line in EDITOR
autoload -Uz edit-command-line && zle -N edit-command-line && \
bindkey "^X^E" edit-command-line
