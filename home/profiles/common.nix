{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.common;
in
{
  options.hurricane.profiles.common = {
    enable = mkEnableOption "common configurations";
  };

  config = mkIf cfg.enable {
    # Install home-manager manpages.
    manual.manpages.enable = true;

    home.packages = with pkgs; [
      # grep alternative.
      ripgrep
      # ls alternative.
      exa
      # cat alternative.
      bat
      # nix stuff
      nix-zsh-completions
      # Simple, fast and user-friendly alternative to find.
      fd
      # More intuitive du.
      du-dust
      # cat for markdown
      mdcat
      # Visualize Nix gc-roots to delete to free space.
      nix-du
      # Keybase
      keybase
      # Show information about the current system
      neofetch
    ];

    hurricane.configs = {
      shell.enable = true;
      sheldon.enable = true;
    };
  };
}
