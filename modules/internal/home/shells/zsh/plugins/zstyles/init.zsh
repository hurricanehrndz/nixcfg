# vim:set ft=sh:
# shellcheck shell=bash disable=SC2148,SC2154,SC2034,SC2086,SC2296,SC1090,SC1091
zstyle ':zephyr:plugin:confd' directory "$ZDOTDIR/conf.d"
zstyle ':zephyr:plugin:editor' symmetric-ctrl-z yes
zstyle ':zephyr:plugin:editor' prepend-sudo yes
zstyle ':zephyr:plugin:editor' glob-alias yes
zstyle ':zephyr:plugin:editor' dot-expansion yes
zstyle ':zephyr:plugin:editor' magic-enter yes
zstyle ':zephyr:plugin:editor' key-bindings vi
zstyle ':zephyr:plugin:zfunctions' directory "$ZDOTDIR/zfuncs"
zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept
