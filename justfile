# This file documents common tasks for this repository.
# Note: You cannot use this justfile during bootstrap unless you sideload `just`,
# since Nix is required to enter the devshell.

default:
    @just --list

### Linux cmds
[group('nix')]
[linux]
build *args:
    nixos-rebuild build --accept-flake-config --flake . {{args}} |& nom
    nvd diff /run/current-system ./result

[group('nix')]
[linux]
switch *args:
    sudo nixos-rebuild switch --accept-flake-config --flake . {{args}} |& nom

[group('nix')]
[linux]
bs *args: (build args) (switch args)

[group('nix')]
[linux]
dev-switch *args: (build "--override-input" "pdenv" "path:$HOME/src/me/pdenv" args)
    sudo nixos-rebuild switch --flake . --override-input pdenv path:../pdenv {{args}} |& nom
alias nds := dev-switch


### Darwin cmds
[group('nix')]
[macos]
bootstrap target:
    ./scripts/bootstrap-darwin {{target}}

[group('nix')]
[macos]
build *args:
    sudo darwin-rebuild build --flake . {{args}} |& nom
    nvd diff /run/current-system ./result

[group('nix')]
[macos]
switch *args:
    sudo darwin-rebuild switch --flake . {{args}} |& nom

[group('nix')]
[macos]
bs *args: (build args) (switch args)

[group('nix')]
[macos]
dev-switch *args: (build "--override-input" "pdenv" "path:$HOME/src/me/pdenv" args)
    sudo darwin-rebuild switch --flake . --override-input pdenv path:$HOME/src/me/pdenv {{args}} |& nom
alias dds := dev-switch


### Chores
[group('nix')]
update *args:
    nix flake update --no-use-registries {{args}}

[group('nix')]
fmt *args:
    nix fmt {{args}}

[group('nix')]
check *args:
    nix flake check {{args}}

[group('nix')]
clean *args:
  sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old
  sudo nix-collect-garbage --delete-older-than 3d {{args}}
