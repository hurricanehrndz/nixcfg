# AGENTS.md - NixOS/nix-darwin Configuration Repository

## Build & Test Commands
- Format code: `nix fmt` (uses alejandra)
- Check flake: `nix flake check`
- Build darwin config: `darwin-rebuild switch --flake .#<hostname>`
- Build nixos config: `nixos-rebuild switch --flake .#<hostname>`
- Show flake outputs: `nix flake show`
- Update flake inputs: `nix flake update`

## Code Style & Conventions
- **Formatting**: Use alejandra (run `nix fmt` before committing)
- **Imports**: Always at the top of file, before `let` bindings
- **Function signatures**: `{ config, lib, pkgs, inputs, ... }:` pattern
- **Lib shorthand**: Use `l = inputs.nixpkgs.lib // builtins;` or `lib` directly
- **Let bindings**: Use `let...in` for local variables
- **Options**: Use `mkOption`, `mkEnableOption`, `mkIf`, `mkDefault`, `mkForce` from lib
- **Naming**: kebab-case for files/directories, camelCase for Nix attributes
- **Line length**: Keep reasonable (Lua uses 120 chars per stylua.toml)
- **Indentation**: 2 spaces (consistent across Nix and Lua)
- **Comments**: Minimal; prefer self-documenting code. Use `##:` for section headers

## Project Structure
- `darwin/` - macOS (nix-darwin) configurations
- `nixos/` - NixOS system configurations
- `home/` - home-manager user configurations
- `profiles/` - Shared system profiles
- `modules/` - Custom NixOS/darwin modules
- `packages/` - Custom package definitions
- `secrets/` - agenix encrypted secrets
