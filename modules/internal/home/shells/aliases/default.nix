{ pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  darwinAliases = {
    nrb = "sudo darwin-rebuild switch --flake .";
  };
  nixosAliases = {
    nrb = "nixos-rebuild switch --sudo";
  };
in
{
  home.shellAliases = {
    mkdir = "mkdir -p";
    rd = "rmdir";

    tm = "tmux new-session -A -s main";

    # alt gnu-utils
    rcat = "cat";
    cat = "bat";

    # nice stuff
    type = "type -a";
    rg = "rg -i -L";
    vimdiff = "nvim -d";

    ssh = "TERM=xterm-256color ssh";
  }
  // (if isDarwin then darwinAliases else nixosAliases);
}
