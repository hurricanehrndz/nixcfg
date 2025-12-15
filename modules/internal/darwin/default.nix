{ lib, pkgs, ... }:
let
  inherit (lib) mkDefault mkForce;
in
{
  # These UI-enhancement plugins come at an even higher performance cost than
  # completion and do not belong in system configuration at all.
  programs.zsh.enableFzfCompletion = mkForce false;
  programs.zsh.enableFzfGit = mkForce false;
  programs.zsh.enableFzfHistory = mkForce false;
  programs.zsh.enableSyntaxHighlighting = mkForce false;

  environment.systemPackages = with pkgs; [
    ncurses
  ];

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
