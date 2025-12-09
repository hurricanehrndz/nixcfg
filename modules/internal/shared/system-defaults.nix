{
  config,
  lib,
  pkgs,
  ...
}:
let
  l = lib // builtins;
in
{
  time.timeZone = l.mkDefault "America/Edmonton";

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  # Install completions for system packages.
  environment.pathsToLink = [
    "/share/bash-completion"
  ]
  ++ (l.optional config.programs.zsh.enable "/share/zsh");

  programs.zsh = {
    enable = l.mkDefault true;
    shellInit = l.mkDefault "";
    loginShellInit = l.mkDefault "";
    interactiveShellInit = l.mkDefault "";

    # Prompts/completions/widgets should never be initialised at the
    # system-level because it will need to be initialised a second time once the
    # user's zsh configs load.
    promptInit = l.mkForce "";
    enableCompletion = l.mkForce false;
    enableBashCompletion = l.mkForce false;
  };
}
