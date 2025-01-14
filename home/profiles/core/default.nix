{
  config,
  pkgs,
  inputs,
  packages,
  ...
}: let
  l = inputs.nixpkgs.lib // builtins;
in {
  imports = [
    ./bat.nix
    ./home-packages.nix
    ./tealdeer.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  xdg.enable = true;
  # manual.json.enable = true;

  ##: essential tools
  programs.command-not-found.enable = true;
  programs.jq.enable = true;
  programs.man.enable = true;

  # more manpages
  programs.man.generateCaches = l.mkDefault true;
  home.enableNixpkgsReleaseCheck = false;
  home.sessionVariables = {
    # fix dobule chars

    # see:
    # https://github.com/ohmyzsh/ohmyzsh/issues/7426
    # https://superuser.com/questions/1607527/tab-completion-in-zsh-makes-duplicate-characters
    LC_CTYPE = "C.UTF-8";
    # Go
    GOPATH = "${config.xdg.dataHome}/go";

    # Rust
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";

    # xdg bin home
    XDG_BIN_HOME = "$HOME/.local/bin";
  };
}
