{
  inputs,
  pkgs,
  ...
}: let
  l = inputs.nixpkgs.lib // builtins;
in {
  imports = [
    ./homebrew.nix
  ];

  # Administrative users on Darwin systems are part of the admin group.
  nix.settings.trusted-users = ["@admin"];

  # FIXME: needs flake-compat
  # nix.nixPath = mkBefore ["darwin-config=${self}"];

  # These UI-enhancement plugins come at an even higher performance cost than
  # completion and do not belong in system configuration at all.
  programs.zsh.enableFzfCompletion = l.mkForce false;
  programs.zsh.enableFzfGit = l.mkForce false;
  programs.zsh.enableFzfHistory = l.mkForce false;
  programs.zsh.enableSyntaxHighlighting = l.mkForce false;

  environment.systemPackages = with pkgs; [
    m-cli
    mas
    ncurses
  ];

  system.activationScripts.postActivation.text = ''
    if [[ -z "$(find /usr/share/terminfo -name "tmux")" ]]; then
      infocmp -x tmux-256color > /tmp/tmux-256color.src
      /usr/bin/tic -x /tmp/tmux-256color.src
    fi
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # https://daiderd.com/nix-darwin/manual/index.html#opt-system.stateVersion
  # $ darwin-rebuild changelog
  system.stateVersion = l.mkDefault 4;
}
