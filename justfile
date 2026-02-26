# This file documents common tasks for this repository.
# Note: You cannot use this justfile during bootstrap unless you sideload `just`,
# since Nix is required to enter the devshell.

default:
    @just --list

[group('nix')]
update *args:
    nix flake update --no-use-registries {{args}}

[group('nix')]
[linux]
rebuild *args:
    sudo nixos-rebuild switch --accept-flake-config --flake . {{args}} |& nom

[group('nix')]
[linux]
build *args:
    nixos-rebuild build --accept-flake-config --flake . {{args}} |& nom

[group('nix')]
[linux]
switch *args:
    @echo 'Activating build...'
    sudo nixos-rebuild switch --accept-flake-config --flake . {{args}} |& nom

[group('nix')]
[linux]
build-switch target: (build target) (switch target)

[group('nix')]
[linux]
dev-rebuild *args:
    sudo nixos-rebuild switch --flake . --override-input pdenv path:../pdenv {{args}} |& nom
alias ndr := dev-rebuild

[group('nix')]
[macos]
build target *args:
    @echo 'Building {{target}}...'
    nix build '.#darwinConfigurations.{{ target }}.system' --accept-flake-config {{args}} |& nom

[group('nix')]
[macos]
switch target *args:
    @echo 'Activating build {{target}}...'
    sudo ./result/sw/bin/darwin-rebuild switch --flake '.#{{target}}' {{args}} |& nom

[group('nix')]
[macos]
build-switch target: (build target) (switch target)

[group('nix')]
[macos]
bootstrap target *args:
    ./scripts/bootstrap-darwin {{target}} {{args}}

[group('nix')]
[macos]
rebuild *args:
    sudo darwin-rebuild switch --flake . {{args}} |& nom

[group('nix')]
[macos]
dev-rebuild *args:
    sudo darwin-rebuild switch --flake . --override-input pdenv path:$HOME/src/me/pdenv {{args}} |& nom
alias dr := dev-rebuild

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
