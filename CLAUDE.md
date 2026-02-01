# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal NixOS/nix-darwin configuration repository that manages multiple systems (both Linux and macOS) using Nix flakes. It uses flake-parts for modular flake organization and easy-hosts for automatic host construction from directory structure.

## Build Commands

### Darwin (macOS)
- Build configuration: `nix build '.#darwinConfigurations.<hostname>.system' --accept-flake-config`
- Apply configuration: `darwin-rebuild switch --flake .#<hostname>`
- Build and switch: `just build-switch <hostname>` (from devshell)
- Development rebuild (with local pdenv): `just dev-rebuild`

### NixOS (Linux)
- Build configuration: `nix build '.#nixosConfigurations.<hostname>.system' --accept-flake-config`
- Apply configuration: `nixos-rebuild switch --flake .#<hostname>`
- Bootstrap install (disables secrets): `nixos-rebuild switch --flake .#<hostname> --override-input bootstrap path:./inputs/flags/true`
- Build and switch: `just build-switch <hostname>`

### General
- Format code: `nix fmt` (uses nixfmt via treefmt)
- Check flake: `nix flake check`
- Update inputs: `nix flake update --no-use-registries`
- Garbage collection: `just gc`
- Enter devshell: `nix develop`

## Architecture

### Flake Structure
The flake uses flake-parts for modular organization:
- `flake.nix` - Entry point that imports `./flake`
- `flake/default.nix` - Main flake-parts configuration that imports per-system config, hosts, and module definitions
- `hosts/default.nix` - Uses easy-hosts flake module for automatic host construction

### Module System
Modules are organized into two categories:
- `modules/exported/` - Modules exposed as flake outputs (darwinModules, nixosModules) for reuse by other flakes
  - `modules/exported/darwin/` - Darwin-specific exported modules
  - `modules/exported/nixos/` - NixOS-specific exported modules
- `modules/internal/` - Private modules used only within this flake
  - `modules/internal/shared/` - Common modules for both Darwin and NixOS
  - `modules/internal/darwin/` - Darwin-specific internal modules
  - `modules/internal/nixos/` - NixOS-specific internal modules
  - `modules/internal/home/` - home-manager modules

The `import-tree` utility automatically imports all Nix files in a directory tree, enabling a directory-based module organization pattern.

### Host Configuration
Hosts are organized by architecture in `hosts/<architecture>/<hostname>/default.nix`. The easy-hosts module:
- Automatically discovers hosts from the directory structure under `hosts/`
- Constructs nixosConfigurations or darwinConfigurations based on the class (nixos/darwin)
- Applies shared modules from `modules/internal/shared/`
- Applies class-specific modules (darwin or nixos) from `modules/internal/`
- Integrates home-manager, agenix, and determinate modules

### Per-System Configuration
`per-system/` contains flake-parts perSystem configuration:
- `args.nix` - Configures pkgs with overlays (agenix, devshell, local packages)
- `shells/` - Development shells with tools like agenix (with yubikey support), darwin-rebuild, nixos-rebuild
- `pkgs/` - Custom packages built per-system
- `treefmt.nix` - Code formatting configuration
- `formatter.nix` - Exposes formatter for `nix fmt`

### Secrets Management
Uses agenix for secret encryption:
- `secrets/secrets.nix` - Defines which secrets exist and which host SSH keys can decrypt them
- `secrets/darwin/` - Darwin-specific encrypted secrets
- Machine SSH keys are defined in `secrets/secrets.nix` under `machineKeys`
- Yubikey age identities are also supported
- After adding a new host, update `secrets/secrets.nix` with the host's public key and run `agenix --rekey`

### Bootstrap Mode
The `bootstrap` flake input (from `inputs/flags/`) controls whether agenix secrets are enabled:
- During initial installation, use `--override-input bootstrap path:./inputs/flags/true` to disable secrets
- After installation, obtain the host SSH key and add it to `secrets/secrets.nix`
- Run `agenix --rekey` to re-encrypt secrets for the new host
- Rebuild without the bootstrap flag to enable secrets

## Code Conventions

### Formatting
- Use nixfmt via treefmt (run `nix fmt` before committing)
- 2-space indentation
- Imports always at the top before `let` bindings

### Module Structure
- Function signature: `{ config, lib, pkgs, inputs, ... }:`
- Lib shorthand: Use `l = inputs.nixpkgs.lib // builtins;` or `lib` directly
- Use `let...in` for local variables
- Use lib functions: `mkOption`, `mkEnableOption`, `mkIf`, `mkDefault`, `mkForce`
- Minimal comments; prefer self-documenting code
- Use `##:` for section headers

### Naming
- Files/directories: kebab-case
- Nix attributes: camelCase
