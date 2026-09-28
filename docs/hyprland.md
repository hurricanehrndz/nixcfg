# Hyprland desktop

A personal Hyprland desktop for one user, enabled per host with
`hrndz.desktop.hyprland.enable`. It takes its look and most of its shell from
[Omarchy](https://github.com/omacom/omarchy), but the pieces are vendored and
composed here rather than run as Omarchy.

| Piece | Where |
| --- | --- |
| System: session (uwsm), SDDM, Plymouth, fonts, portals, prebuilt binaries, `desktop-vnc` | `modules/internal/nixos/desktop/hyprland/` |
| User: Hyprland config, bindings, rules, monitors, shell service and config | `modules/internal/home/desktop/hyprland/` |
| Desktop shell (bar, menu, panels, lock, notifications, OSD) | `per-system/pkgs/by-name/hrndz-shell/` |
| Login screen theme | `per-system/pkgs/by-name/hrndz-sddm-theme/` |
| Ambient video for wallpaper, screensaver, lock and login | `ambient-set`, `modules/internal/nixos/desktop/hyprland/ambient.nix` |

## Why it deviates from Omarchy

Omarchy is a distribution for many users. It installs packages at runtime,
switches between bundled themes, and loads plugins cloned from git. Running
that on NixOS means maintaining an adapter for each of those mechanisms, and
every upstream update touches all of them. This desktop has one user and one
source of truth, so it keeps the parts worth keeping and drops the machinery:

- **Nix installs everything.** Apps come from `hrndz.*` roles and tooling,
  `environment.systemPackages` or `home.packages`. The shell reads desktop
  entries; it never installs or removes packages.
- **No plugins.** Any feature we want from an Omarchy or nixarchy plugin gets
  vendored into the shell anyway, so a runtime plugin system would only
  load code we already ship. Features are fixed at build time.
- **One theme.** Colours come from `hrndz.theme.scheme` through Stylix, the
  same scheme as every other host. There is no theme switcher.
- **One menu.** `Super+Space`, the bar button and the power key open the same
  searchable palette of apps and actions.
- **Our bindings.** Keys follow the AeroSpace setup on macOS: Meh
  (`Ctrl+Shift+Alt`) focuses and switches to named workspaces, Hyper
  (`Super+Ctrl+Shift+Alt`) moves windows. `Super+K` lists every binding.
- **Frozen fork.** `hrndz-shell` no longer tracks upstream. Its source revision
  and licence are in `package.nix`. Internal ids such as `omarchy.bar` keep
  their upstream names.

What we did take from nixarchy is its prebuilt-binary support (nix-ld with its
library list, envfs, AppImage binfmt).

## Adopting a feature

Keep the desktop features we use, but own their composition here. This limits
the upstream code and helper scripts we maintain for each feature.

1. Trace the upstream feature's entry point, callers, commands, assets, and
   required services. Check for an equivalent already in `hrndz-shell` or Nix.
2. Copy the smallest working part. Record its upstream repository, revision,
   and licence near the copied files or in `package.nix`. Replace upstream
   paths and mutable setup with Nix-owned paths and options.
3. Wire it into the existing shell and menu. Prefer Quickshell APIs for UI and
   session state; add a helper script only when the UI needs an OS command
   Quickshell cannot provide. Do not add a second launcher, plugin installer,
   clone registry, package-management menu, or generic provider framework.
4. Remove superseded code and dependencies after finding every caller. Run the
   flake and format checks, and test the UI in a Hyprland session before
   calling a runtime change done.

Places to look for ideas:

- [omacom/omarchy](https://github.com/omacom/omarchy): shell visuals and
  controls, and the source of the fork.
- [olafkfreund/nixarchy](https://github.com/olafkfreund/nixarchy): adapting
  Omarchy to NixOS.
- [olafkfreund/nixarchy-menu](https://github.com/olafkfreund/nixarchy-menu):
  searchable palette behaviour.
- [ChrisTitusTech/dwm-titus](https://github.com/ChrisTitusTech/dwm-titus): a
  small, personally maintained desktop to compare maintenance choices.

## Current boundary

`shell.qml` declares every bundled component directly: services, the
summoned windows (menu, clipboard, emojis, OSD) and the bar widgets the
layout can name. There are no manifests and no plugin scan. Lock and polkit
are the exception: they are created without a parent so nothing can walk the
object tree to them. Add a component by importing its directory and declaring
it there. Don't remove a used panel just because its upstream implementation
is large.

The bar still edits its layout at runtime (drag to reorder, move edge,
transparency) through `mutateShellConfig`; those edits last until the shell
restarts.

The shell has one bar and no runtime extension points: no replacement bars
and no bar widgets loaded from a local QML file. Add a feature by vendoring its
code into the package. Bar entries with `exec` (command widgets) remain.

## Apps and capture

`modules/internal/nixos/desktop/hyprland/apps.nix` installs the everyday
apps from Omarchy's base set and makes Celluloid, Papers and imv the default
apps for video, PDF and images. Screenshots use Omarchy's omasnap, built in
`per-system/pkgs/by-name/omasnap` from the `omasnap` flake input, which follows
upstream's main branch; if `just update` breaks its build, pin the input to a
tag. Recording is `hrndz-shell screenrecord`, which runs gpu-screen-recorder
with the capture helper that `programs.gpu-screen-recorder` sets up. With
`--webcam` it shows a camera (asking which when there are several; v4l-utils
finds them) in a pinned mpv window in the recorded area's corner
(`Super+Alt+[`/`]` or `hrndz-shell webcam` resize it). `hrndz-shell ocr` and `qr` copy
the text or QR code in a region; a QR value is marked sensitive, so the
clipboard history skips it. All of them call `omarchy-notification-send`,
vendored into the shell, so clicking the notification opens the capture. A
capture taken while the display is DPMS-off fails; that is the compositor, not
the tools.

## Display scale

The display panel previews a new scale for 15 seconds and reverts unless you
keep it. Kept scales are stored per connector in
`~/.config/hypr/monitors.lua`, which also sets `GDK_SCALE` to the largest
scale, rounded, for XWayland apps. The shell rewrites that file, so put
hand-written monitor rules in the Hyprland config instead.

## Remote access

`desktop-vnc` serves the session over VNC on `127.0.0.1:5900`; the README has
the commands. With nobody logged in, it starts a headless session
(`hyprland-headless` user unit, libseat's `noop` backend) and, without a
connected display, adds a virtual output `VNC-1`. If a monitor is connected,
it locks that session before serving it. `stop` removes only what `start`
created. Linger keeps a session started over SSH alive after SSH disconnects.

Agents can drive it with, for example,
`uvx --from vncdotool vncdo -s 127.0.0.1::5900 key super-enter`, or screenshot
it with `grim -o VNC-1`.
