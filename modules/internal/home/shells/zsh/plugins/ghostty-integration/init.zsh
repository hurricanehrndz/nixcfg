# vim:set ft=sh:
# shellcheck shell=bash disable=SC2148,SC2154,SC2034,SC2086,SC2296,SC1090,SC1091,SC2140

if [[ -n "$_GHOSTTY_INTEGRATION_SOURCED" ]] || [[ -z "${GHOSTTY_RESOURCES_DIR}" ]]; then
    return
fi
_GHOSTTY_INTEGRATION_SOURCED=1

# Get the path to this script
0=${(%):-%N}

# Ghostty shell integration for zsh
builtin source "${0:a:h}/ghostty-integration.plugin.zsh"
