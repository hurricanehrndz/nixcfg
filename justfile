# This file documents common tasks for this repository.
# Note: You cannot use this justfile during bootstrap unless you sideload `just`,
# since Nix is required to enter the devshell.

default:
    @just --list

[group('nix')]
update:
    nix flake update --no-use-registries

[group('nix')]
[linux]
rebuild:
    sudo nixos-rebuild switch --flake .

[group('nix')]
[linux]
build target:
    nix build '.#nixosConfigurations.{{ target }}.system' --accept-flake-config

[group('nix')]
[linux]
switch target:
    @echo 'Activating build {{target}}...'
    sudo ./result/sw/bin/nixos-rebuild switch --flake --accept-flake-config '.#{{target}}'

[group('nix')]
[linux]
build-switch target: (build target) (switch target)

[group('nix')]
[linux]
dev-rebuild:
    sudo nixos-rebuild switch --flake . --override-input pdenv path:../pdenv

[group('nix')]
[macos]
build target:
    @echo 'Building {{target}}...'
    nix build '.#darwinConfigurations.{{ target }}.system' --accept-flake-config

[group('nix')]
[macos]
switch target:
    @echo 'Activating build {{target}}...'
    sudo ./result/sw/bin/darwin-rebuild switch --flake '.#{{target}}'

[group('nix')]
[macos]
build-switch target: (build target) (switch target)

[group('nix')]
[macos]
bootstrap target:
    ./scripts/bootstrap-darwin {{target}}

[group('nix')]
[macos]
rebuild:
    sudo darwin-rebuild switch --flake .

[group('nix')]
[macos]
dev-rebuild:
    sudo darwin-rebuild switch --flake . --override-input pdenv path:$HOME/src/me/pdenv
alias dr := dev-rebuild

[group('nix')]
fmt:
    nix fmt

[group('nix')]
check:
    nix flake check

[group('nix')]
gc:
  sudo nix-collect-garbage -d
  nix-collect-garbage -d
