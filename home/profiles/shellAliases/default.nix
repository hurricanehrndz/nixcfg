{ pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
  darwinAliases = {
    nrb = "sudo darwin-rebuild switch --flake ~/src/me/nixcfg";
  };
  nixosAliases = {
    nrb = "nixos-rebuild switch --sudo";
  };
in
{
  home.shellAliases = {
    # mods - cli gpt client
    "?" = "gpt -C";

    # quick cd
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";

    # https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/directories.zsh
    "-" = "cd -";
    "1" = "cd -1";
    "2" = "cd -2";
    "3" = "cd -3";
    "4" = "cd -4";
    "5" = "cd -5";
    "6" = "cd -6";
    "7" = "cd -7";
    "8" = "cd -8";
    "9" = "cd -9";

    mkdir = "mkdir -p";
    rd = "rmdir";

    tm = "tmux new-session -A -s main";

    # alt gnu-utils
    cd = "z";
    rcat = "cat";
    cat = "bat";

    # nice stuff
    type = "type -a";
    rg = "rg -i -L";
    vimdiff = "nvim -d";
    tree = "eza --icons=auto -T --header";
    lt = "eza --icons=auto -T --header ";

    # virsh
    virsh = "virsh --connect='qemu:///system'";
    virt-install = "virt-install --connect 'qemu:///system'";
    ssh = "TERM=xterm-256color ssh";
  }
  // (if isDarwin then darwinAliases else nixosAliases);
}
