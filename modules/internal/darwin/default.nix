{ lib, ... }:
let
  inherit (lib) mkDefault mkForce;
in
{
  # These UI-enhancement plugins come at an even higher performance cost than
  # completion and do not belong in system configuration at all.
  programs.zsh.enableGlobalCompInit = mkForce false;
  programs.zsh.enableFzfCompletion = mkForce false;
  programs.zsh.enableFzfGit = mkForce false;
  programs.zsh.enableFzfHistory = mkForce false;
  programs.zsh.enableSyntaxHighlighting = mkForce false;
  environment.etc."zshrc".text = mkForce ''
    # /etc/zshrc: DO NOT EDIT -- this file has been generated automatically.
    # This file is read for interactive shells.

    # Only execute this file once per shell.
    if [ -n "$__ETC_ZSHRC_SOURCED" -o -n "$NOSYSZSHRC" ]; then return; fi
    __ETC_ZSHRC_SOURCED=1

    # Setup command line history.
    # Don't export these, otherwise other shells (bash) will try to use same HISTFILE.
    SAVEHIST=1000
    HISTSIZE=1000
    HISTFILE="$HOME/.config/zsh/.zsh_history"

    setopt HIST_IGNORE_DUPS SHARE_HISTORY HIST_FCNTL_LOCK

    # Read system-wide modifications.
    if test -f /etc/zshrc.local; then
      source /etc/zshrc.local
    fi
  '';

  system.activationScripts.postActivation.text = ''
    if [[ -z "$(find /usr/share/terminfo -name "tmux")" ]]; then
      /usr/bin/infocmp -x tmux-256color > /tmp/tmux-256color.src
      /usr/bin/tic -x /tmp/tmux-256color.src
    fi
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # https://daiderd.com/nix-darwin/manual/index.html#opt-system.stateVersion
  # $ darwin-rebuild changelog
  system.stateVersion = mkDefault 6;
}
