# AGENTS.md - NixOS/nix-darwin Configuration Repository

## Build & Test Commands
- Format code: `nix fmt` (nixfmt via treefmt)
- Check flake: `nix flake check`
- Build darwin config: `darwin-rebuild switch --flake .#<hostname>`
- Build nixos config: `nixos-rebuild switch --flake .#<hostname>`
- Build nixos bootstrap config (initial install): `nixos-rebuild switch --flake .#<hostname> --override-input bootstrap path:./inputs/flags/true`
- Show flake outputs: `nix flake show`
- Update flake inputs: `nix flake update`

## Code Style & Conventions
- **Formatting**: Use nixfmt via treefmt (run `nix fmt` before committing)
- **Imports**: Always at the top of file, before `let` bindings
- **Function signatures**: `{ config, lib, pkgs, inputs, ... }:` pattern
- **Lib shorthand**: Use `l = inputs.nixpkgs.lib // builtins;` or `lib` directly
- **Let bindings**: Use `let...in` for local variables
- **Options**: Use `mkOption`, `mkEnableOption`, `mkIf`, `mkDefault`, `mkForce` from lib
- **Naming**: kebab-case for files/directories, camelCase for Nix attributes
- **Line length**: Keep reasonable
- **Indentation**: 2 spaces
- **Comments**: Minimal; prefer self-documenting code. Use `##:` for section headers

## Project Structure
- `flake/` - Flake module definitions (darwin/nixos modules)
- `hosts/` - Host-specific configurations (aarch64-darwin, etc.)
- `modules/` - Custom modules (exported and internal)
- `per-system/` - Per-system configurations (pkgs, shells, treefmt, args)
- `secrets/` - agenix encrypted secrets
- `identities/` - Age and GPG identity files
- `inputs/` - Flake input configurations and flags
