# AGENTS.md

This file provides guidance to coding agents (Claude Code, etc.) when working
with code in this repository.

## Overview

This is a personal NixOS/nix-darwin configuration repository that manages multiple systems (both Linux and macOS) using Nix flakes. It uses flake-parts for modular flake organization and easy-hosts for automatic host construction from directory structure. The Nix daemon is [Lix](https://lix.systems/) (see `per-system/shells/default.nix`).

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for a detailed explanation of how the repository is organized.

## Build Commands

Most workflows go through the `justfile`, which wraps rebuilds with
`nix-output-monitor` (nom) and shows a diff via `nvd`. Recipes are
platform-gated (`[macos]` / `[linux]`), so the same names work on both.

### Darwin (macOS)
- Build: `just build` (runs `sudo darwin-rebuild build` + `nvd diff`)
- Switch: `just switch`
- Build + switch: `just bs`
- Dev rebuild with local pdenv: `just dev-switch` (alias `dds`)
- Initial bootstrap: `just bootstrap <hostname>` (runs `scripts/bootstrap-darwin`)

### NixOS (Linux)
- Build: `just build` (runs `nixos-rebuild build` + `nvd diff`)
- Switch: `just switch`
- Build + switch: `just bs`
- Dev rebuild with local pdenv: `just dev-switch` (alias `nds`)
- Bootstrap install (disables secrets): `nixos-rebuild switch --flake .#<hostname> --override-input bootstrap github:boolean-option/true`

### Raw nix (without just)
- Build Darwin: `nix build '.#darwinConfigurations.<hostname>.system' --accept-flake-config`
- Build NixOS: `nix build '.#nixosConfigurations.<hostname>.system' --accept-flake-config`
- Apply: `darwin-rebuild switch --flake .#<hostname>` / `nixos-rebuild switch --flake .#<hostname>`

### General
- Format code: `nix fmt` or `just fmt` (nixfmt/shfmt/shellcheck via treefmt)
- Check flake: `nix flake check` or `just check`
- Update inputs: `just update` (`nix flake update --no-use-registries`)
- Lock inputs: `just lock`
- Garbage collection: `just clean` (deletes old system generations + GC older than 3d)
- Enter devshell: `nix develop` (or `nix develop --impure` when using `$PRJ_ROOT`)

## Justfile Shortcuts
- `just` / `just default` - list available recipes
- `just build` - build the current-platform configuration (+ `nvd diff`)
- `just switch` - build and activate
- `just bs` - build then switch
- `just dev-switch` - switch with local `pdenv` overridden to `~/src/me/pdenv`
- `just bootstrap <host>` - (macOS) run the Darwin bootstrap script
- `just fmt` / `just check` / `just update` / `just lock`
- `just clean` - prune old generations and garbage collect
- `just test-scrutiny-notify` / `just scrutiny-logs` - ops diagnostics for DeepThought

## Troubleshooting
- `builtins.toFile`/`options.json` warnings during `nix flake check` come from nixpkgs option docs generation, not this repo. They can be ignored or silenced by disabling NixOS docs (`documentation.nixos.enable = false`) if desired.

## Local Helper Scripts
- `scripts/bootstrap-darwin` - installs Lix + Homebrew and bootstraps a Darwin host (invoked by `just bootstrap`)
- `scripts/flake-check-lite` - runs `nix flake check --no-build --show-trace` and summarizes warnings/errors
- `scripts/nix-deprecation-scan` - scans Nix files for common deprecated APIs
- `scripts/update-brave-origin-beta` - updates the Brave beta cask source

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
  - `modules/internal/home/` - home-manager modules. Program modules under `home/programs/` are grouped by concern: `ai/` (Claude + pi agents, rtk), `languages/` (per-language toolchains), `extras.nix` (a small misc-utils bucket), and individual tools at the top level.

The `import-tree` utility automatically imports all Nix files in a directory tree, enabling a directory-based module organization pattern.

### Host Configuration
Hosts are organized by architecture in `hosts/<architecture>/<hostname>/default.nix`. The easy-hosts module:
- Automatically discovers hosts from the directory structure under `hosts/`
- Constructs nixosConfigurations or darwinConfigurations based on the class (nixos/darwin)
- Applies shared modules from `modules/internal/shared/`
- Applies class-specific modules (darwin or nixos) from `modules/internal/`
- Integrates home-manager, agenix, and (NixOS only) disko modules

### Host Capability Options (`hrndz`)
Host capabilities are toggled through `hrndz.*` options defined in `modules/internal/shared/options.nix`, then enabled per-host (typically in `hosts/<arch>/<host>/config/users/hurricane.nix` or the host `default.nix`):
- `roles.terminalDeveloper` / `roles.guiDeveloper` — developer-environment roles. `guiDeveloper` implies `terminalDeveloper`, which defaults `cli.enable = true`.
- `tooling.*` — opt-in toggles for heavier/optional tooling: `ai`, `python`, `ruby`, `js`, `golang`, `extras`, `virtualization`, `macadmin`.

These gates are an allowlist whose purpose is to keep heavy/dev tooling **off** low-end hosts (e.g. `hal`, which enables none of them). Put heavy packages behind an existing `tooling.*` gate rather than installing them unconditionally, then enable it per-host. AI tooling is gated on `tooling.ai`, independent of `roles.terminalDeveloper`.

### Per-System Configuration
`per-system/` contains flake-parts perSystem configuration:
- `args.nix` - Configures pkgs with overlays (agenix, devshell, local packages)
- `shells/` - devshell (Lix, nom, nvd, treefmt; agenix with yubikey support, age, git-age-filter; darwin-rebuild on macOS)
- `pkgs/` - Custom packages built per-system
- `treefmt.nix` - Code formatting configuration
- `formatter.nix` - Exposes formatter for `nix fmt`

### Secrets Management
Uses agenix for secret encryption:
- `secrets/secrets.nix` - Defines which secrets exist and which host SSH keys can decrypt them (`machineKeys`, `yubikeys`)
- `secrets/darwin/`, `secrets/home/`, `secrets/services/` - encrypted secrets grouped by scope
- Machine SSH keys are defined in `secrets/secrets.nix` under `machineKeys`; yubikey age identities under `yubikeys`
- After adding a new host, update `secrets/secrets.nix` with the host's public key and run `agenix --rekey`
- Some working-tree files are also encrypted at rest via `git-age-filter` (see `docs/manual-nixos-install.md` and the README "Secrets" section)

### Bootstrap Mode
The `bootstrap` flake input (`github:boolean-option/false` by default, see `flake.nix`) controls whether agenix secrets are enabled:
- During initial installation, use `--override-input bootstrap github:boolean-option/true` to disable secrets
- After installation, obtain the host SSH key and add it to `secrets/secrets.nix`
- Run `agenix --rekey` to re-encrypt secrets for the new host
- Rebuild without the bootstrap flag to enable secrets

## Code Conventions

### Formatting
- Use treefmt (run `nix fmt` or `just fmt` before committing): nixfmt for Nix, shfmt + shellcheck for shell scripts
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
