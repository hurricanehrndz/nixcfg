{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.shell;
in
{
  options.hurricane = {
    configs.shell.enable = mkEnableOption "enable awsome zsh config";
  };
  config = mkIf cfg.enable {
    # Enable shell management
    programs.zsh = {
      enable = true;
      autocd = true;
      enableCompletion = false; # Enable when ready
      defaultKeymap = "viins";
      dotDir = ".config/zsh";
      history = {
        extended = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        path = ".config/zsh/.zsh_history";
      };
      shellAliases = with pkgs; {
        # Aliases that make commands colourful.
        "grep" = "${gnugrep}/bin/grep --color=auto";
        "fgrep" = "${gnugrep}/bin/fgrep --color=auto";
        "egrep" = "${gnugrep}/bin/egrep --color=auto";
      };
      initExtra = ''
        source "${pkgs.grc}/etc/grc.zsh"
      '';
    };
    programs.skim = {
      enable = true;
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        directory = {
          truncate_to_repo = false;
          fish_style_pwd_dir_length = 1;
        };
        cmd_duration.disabled = true;
      };
    };
    # Enable XDG User Directories
    xdg.enable = true;

    # my favorite utils
    home.packages = with pkgs; [
      # colorizer
      grc
      # sed alt
      sd
      # tldr alt
      tealdeer
      # network bech util
      bandwhich
      # command line benchmark util - time alternativ
      hyperfine
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

  };
}
