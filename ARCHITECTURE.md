# Architecture

## Overview

This is a NixOS/nix-darwin configuration repository managing multiple systems
(Linux and macOS) using Nix flakes. It uses
[flake-parts](https://github.com/hercules-ci/flake-parts) for modular flake
organization and
[easy-hosts](https://github.com/tgirlcloud/easy-hosts) for automatic host
construction from directory structure.

## Directory Layout

```
.
├── flake.nix                  # Flake entry point, delegates to ./flake
├── flake/                     # flake-parts module definitions
│   ├── default.nix            # Main config: imports hosts, per-system, module exports
│   ├── darwinModules.nix      # Exported darwinModules flake output
│   ├── nixosModules.nix       # Exported nixosModules flake output
│   ├── homeModules.nix        # Exported homeModules flake output
│   └── lib/                   # Flake-level library functions
├── hosts/                     # Per-host configurations
│   ├── default.nix            # easy-hosts setup: auto-discovers hosts, wires modules
│   ├── aarch64-darwin/        # macOS hosts (Apple Silicon)
│   │   ├── HX7YG952H5/
│   │   └── LH9KCR6DJX/
│   └── x86_64-nixos/          # NixOS hosts (x86_64)
│       └── DeepThought/
├── modules/
│   ├── exported/              # Modules exposed as flake outputs for reuse
│   │   ├── darwin/services/   # aerospace, superkey
│   │   └── nixos/services/    # ingress
│   └── internal/              # Private modules used only by this flake
│       ├── shared/            # Applied to ALL hosts (darwin + nixos)
│       ├── darwin/            # Darwin-only modules
│       ├── nixos/             # NixOS-only modules
│       └── home/              # home-manager modules (applied via shared)
├── per-system/                # flake-parts perSystem configuration
│   ├── args.nix               # pkgs with overlays
│   ├── shells/                # Development shells (agenix, rebuild tools)
│   ├── pkgs/                  # Custom packages (pkgs-by-name pattern)
│   ├── treefmt.nix            # Code formatting config
│   └── formatter.nix          # Exposes formatter for `nix fmt`
├── secrets/                   # agenix-encrypted secrets
│   ├── secrets.nix            # Secret definitions + host key mapping
│   ├── darwin/                # Darwin-specific secrets
│   └── services/              # Service secrets (homarr, ingress, etc.)
├── identities/                # Public keys (age recipients, GPG)
├── inputs/flags/              # Bootstrap flag flakes (true/false)
└── scripts/                   # Helper shell scripts
```

## How It Fits Together

### Flake Entry Point

`flake.nix` defines inputs and delegates all outputs to flake-parts:

```
flake.nix → flake-parts.lib.mkFlake → ./flake/default.nix
```

`flake/default.nix` imports three concerns:
1. **Hosts** (`hosts/default.nix`) — system configurations
2. **Per-system** (`per-system/`) — packages, shells, formatters
3. **Module exports** (`flake/darwinModules.nix`, etc.) — reusable modules

### Host Construction (easy-hosts)

`hosts/default.nix` uses the easy-hosts flake module to automatically discover
and construct system configurations:

```
hosts/<architecture>/<hostname>/default.nix
      └─ aarch64-darwin → darwinConfigurations
      └─ x86_64-nixos   → nixosConfigurations
```

For each host, easy-hosts:
1. Applies **shared modules** from `modules/internal/shared/`
2. Applies **class-specific modules** based on whether the host is `darwin` or
   `nixos` (from `modules/internal/darwin/` or `modules/internal/nixos/`)
3. Integrates upstream modules: home-manager, determinate, agenix, disko (NixOS
   only), and exported modules from this flake

### Module Organization

Modules under `modules/internal/` are auto-imported using
[import-tree](https://github.com/vic/import-tree), which recursively imports
all `.nix` files in a directory tree. This means adding a new `.nix` file to
any of these directories automatically includes it — no manual import list to
maintain.

**Shared modules** (`modules/internal/shared/`) run on every host and handle
cross-platform concerns: nix settings, nixpkgs overlays, agenix setup,
home-manager integration, fonts, environment variables, and custom options.

**Class-specific modules** handle platform-only concerns:
- `darwin/` — macOS preferences (dock, finder, keyboard, etc.), homebrew,
  aerospace window manager, networking (computerName/localHostName)
- `nixos/` — base system defaults, openssh hardening, networking (networkd),
  services (media stack, dashboards, container auto-updates)

**Home modules** (`modules/internal/home/`) configure user-level programs via
home-manager: shell (zsh with custom plugins), git, gpg, tmux, fzf, neovim,
ghostty, and development tooling.

**Exported modules** (`modules/exported/`) are exposed as flake outputs
(`darwinModules`, `nixosModules`, `homeModules`) so other flakes can reuse
them. These define self-contained services like aerospace and ingress.

### Custom Options

`modules/internal/shared/options.nix` defines the `hrndz` option namespace
used throughout the configuration to toggle features per host:

- `hrndz.roles.*` — role-based feature sets (e.g., `terminalDeveloper`)
- `hrndz.tooling.*` — language tooling toggles (js, python, ruby)
- `hrndz.services.*` — service toggles

### Secrets Management (agenix)

Secrets are encrypted with [agenix](https://github.com/ryantm/agenix) using
host SSH keys and yubikey age identities:

- `secrets/secrets.nix` maps secret files to the host keys that can decrypt
  them
- `identities/age/` holds age public keys and yubikey identity files
- The `bootstrap` flake input (`inputs/flags/`) controls whether secrets are
  enabled — set to `true` during initial install when host keys don't yet exist

### Per-System Configuration

`per-system/` uses flake-parts `perSystem` to define outputs that vary by
system architecture:

- **pkgs** — nixpkgs configured with overlays (agenix, devshell, snapraid-runner,
  local packages)
- **devShells** — development shell with agenix (yubikey support),
  darwin-rebuild/nixos-rebuild, and other tools
- **packages** — custom packages following the pkgs-by-name convention
- **formatter** — nixfmt via treefmt for `nix fmt`

### Nix Settings

Nix configuration is centralized in `modules/internal/shared/nix-settings.nix`:

- **All hosts**: flake registry pinned to inputs, `nixPath` set, input sources
  symlinked into `/etc/nix/inputs`
- **NixOS**: `nix.settings` with caches, substituters, and weekly GC
- **Darwin**: `nix.enable = false` (defers to Determinate Nix) with
  `determinateNix.customSettings` reusing the same cache/substituter config

## Key Inputs

| Input | Purpose |
| --- | --- |
| `nixpkgs` (follows `nixpkgs-unstable-weekly`) | Package set |
| `flake-parts` | Modular flake organization |
| `easy-hosts` | Auto host discovery from directory structure |
| `import-tree` | Recursive directory-based module imports |
| `determinate` | Determinate Nix daemon modules |
| `home-manager` | User environment management |
| `darwin` (nix-darwin) | macOS system configuration |
| `agenix` | Secret encryption with age |
| `disko` | Declarative disk partitioning |
| `devshell` | Development shell framework |
| `treefmt-nix` | Code formatting |
| `pdenv` | Personalized neovim distribution |
