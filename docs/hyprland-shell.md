# Hyprland shell

`hrndz-shell` is a frozen fork of Omarchy's Quickshell shell. The source and
revision are recorded in `per-system/pkgs/by-name/hrndz-shell/package.nix`.
Home Manager writes its configuration and theme; the package ships the QML and
the command helpers it needs. Only bundled components load. The registry
rejects clone manifests, but the shell host still carries plugin API code.

## The curated shell model

Keep the desktop features we use, but own their composition here. This limits
the amount of upstream code and helper scripts we must maintain each time we
adopt a feature.

- Nix owns installed applications and system services. The shell reads desktop
  entries; it does not install packages.
- There is one menu component. `Super+Space` opens a searchable palette of apps
  and actions. Bar and power-key routes use that same component. Volume and
  display scale remain first-class controls in the shell.
- Shell features are selected in this repository. Omarchy plugins are sources
  of ideas and code, not runtime dependencies. Keep the useful QML behavior and
  its necessary assets, then wire it into the fixed shell.
- Prefer Quickshell APIs for UI and session state. Reuse an existing helper for
  an OS command; add a helper only when the UI needs a command or service that
  Quickshell cannot provide directly. Avoid copying an upstream script tree.

## Repositories for inspiration

- [omacom/omarchy](https://github.com/omacom/omarchy): shell visuals, controls,
  and the source of the current fork.
- [ChrisTitusTech/dwm-titus](https://github.com/ChrisTitusTech/dwm-titus): a
  smaller, personally maintained desktop setup to compare maintenance choices.
- [olafkfreund/nixarchy](https://github.com/olafkfreund/nixarchy): examples of
  adapting Omarchy to NixOS.
- [olafkfreund/nixarchy-menu](https://github.com/olafkfreund/nixarchy-menu):
  searchable palette behavior for the one-menu design.

## Adopting a feature

1. Trace the upstream feature's entry point, callers, commands, assets, and
   required services. Check for an equivalent already in `hrndz-shell` or Nix.
2. Copy the smallest working part. Record its upstream repository, revision,
   and license near the copied files or in `package.nix`. Replace upstream
   paths and mutable setup with Nix-owned paths and options.
3. Wire it into the existing shell and menu. Do not add a second launcher,
   plugin installer, clone registry, package-management menu, or generic
   provider framework for one feature.
4. Remove superseded code and dependencies after finding every caller. Verify
   the focused behavior, run the flake and format checks, and test the UI in a
   Hyprland session before declaring a runtime migration complete.

## Current boundary

The palette and controls follow this model, but the host still discovers
bundled components through `PluginRegistry.qml`. `shell.qml` also retains
scoped plugin APIs and mutable bar-layout code inherited from Omarchy.
Simplifying that host is separate work: move each live component to a direct,
fixed reference, keep its behavior, then delete the registry path it no longer
uses.
Do not remove a used panel merely because the upstream implementation is large.
