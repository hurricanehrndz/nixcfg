{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.shell;
  zshPlugins = (import ./zsh-plugins.nix pkgs).plugins;
  zshAliases = (import ./zsh-aliases.nix pkgs).aliases;
  zshrcBeforeCompInit = (import ./zshrc-BeforeCompInit.nix pkgs).zshrcBeforeCompInit;
  zshenvExtra = (import ./zshenv-extra.nix pkgs).zshenvExtra;
in {
  options.hurricane = { configs.shell.enable = mkEnableOption "enable awsome zsh config"; };
  config = mkIf cfg.enable {
    hurricane.configs.zplugins = {
      enable = true;
      plugins = zshPlugins;
    };

    # Enable shell management
    programs.zsh = {
      enable = true;
      # autocd = true;
      enableCompletion = false; # Enable when ready
      dotDir = ".config/zsh";
      history = {
        extended = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        path = "${config.xdg.configHome}/zsh/zsh_history";
      };
      envExtra = zshenvExtra;
      initExtraBeforeCompInit = zshrcBeforeCompInit;
      shellAliases = zshAliases;
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
        aws.disabled = true;
        scan_timeout = 10;
      };
    };
    # Enable XDG User Directories
    xdg.enable = true;

    # my favorite utils
    home.packages = with pkgs; [
      (writeScriptBin "print-colors" (builtins.readFile ./print-colors))
      (writeScriptBin "test-truecolors" (builtins.readFile ./test-truecolors))
      (writeScriptBin "rtfm" (builtins.readFile ./rtfm))
      # top alternativ
      bottom
      # fuzzy finder
      skim
      fzf
      # curl
      curl
      # gnu awk
      gawk
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
      nix-zsh-completions
      zsh-completions
    ];

    home.sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BAT_THEME = "TwoDark";
    };
    programs.bat = {
      enable = true;
      config = {
        theme = config.home.sessionVariables.BAT_THEME;
        pager = "less -FRI";
      };
    };
  };
}
