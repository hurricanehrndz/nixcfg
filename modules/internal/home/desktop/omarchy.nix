{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = osConfig.hrndz.desktop.omarchy or { };
  enabled = (cfg.enable or false) && isLinux;
  omarchyPath = "${cfg.package}/share/omarchy";
  stateDir = "${config.home.homeDirectory}/.local/state/omarchy";

  # Chords, spelled the way AeroSpace's are on macOS.
  meh = "CTRL + SHIFT + ALT";
  hyper = "SUPER + CTRL + SHIFT + ALT";

  # Named workspaces mirror the AeroSpace config.
  namedWorkspaces = [
    "W"
    "A"
    "R"
    "S"
    "T"
    "V"
    "C"
    "B"
    "D"
    "F"
  ];

  directions = {
    H = "l";
    J = "d";
    K = "u";
    L = "r";
  };

  bind =
    keys: desc: dispatcher:
    ''o.bind("${keys}", "${desc}", ${dispatcher})'';

  bindingsLua = ''
    -- Managed by Nix: modules/internal/home/desktop/omarchy.nix.
    -- Loaded after Omarchy's defaults. Keys Omarchy already binds are unbound
    -- first, so these replace them; everything else is added alongside.

    -- Replaced Omarchy defaults.
    hl.unbind("SUPER + L")
    hl.unbind("ALT + TAB")
    hl.unbind("ALT + SHIFT + TAB")

    ${bind "SUPER + L" "Lock screen" ''"omarchy-system-lock"''}
    ${bind "ALT + TAB" "Previous workspace" ''hl.dsp.focus({ workspace = "previous" })''}
    ${bind "ALT + SHIFT + TAB" "Move workspace to next monitor"
      ''hl.dsp.workspace.move({ monitor = "+1" })''
    }

    -- Session.
    ${bind "SUPER + Q" "Close window" "hl.dsp.window.close()"}
    ${bind "SUPER + M" "Exit session" ''"uwsm stop"''}

    -- Focus and move, matching AeroSpace h/j/k/l.
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: dir: bind "${meh} + ${key}" "Focus ${dir}" ''hl.dsp.focus({ direction = "${dir}" })''
      ) directions
    )}
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: dir:
        bind "${hyper} + ${key}" "Move window ${dir}" ''hl.dsp.window.swap({ direction = "${dir}" })''
      ) directions
    )}

    -- Resize and split, matching AeroSpace minus/equal intent.
    ${bind "${meh} + code:20" "Shrink window"
      "hl.dsp.window.resize({ x = -50, y = 0, relative = true })"
    }
    ${bind "${meh} + code:21" "Grow window" "hl.dsp.window.resize({ x = 50, y = 0, relative = true })"}
    ${bind "${meh} + slash" "Toggle split" ''hl.dsp.layout("togglesplit")''}
    ${bind "${meh} + comma" "Swap split" ''hl.dsp.layout("swapsplit")''}

    -- Named workspaces.
    ${lib.concatMapStringsSep "\n" (
      ws: bind "${meh} + ${ws}" "Workspace ${ws}" ''hl.dsp.focus({ workspace = "name:${ws}" })''
    ) namedWorkspaces}
    ${lib.concatMapStringsSep "\n" (
      ws:
      bind "${hyper} + ${ws}" "Move window to workspace ${ws}"
        ''hl.dsp.window.move({ workspace = "name:${ws}" })''
    ) namedWorkspaces}
  '';

  # Menu rows that assume pacman or nixarchy's app installer. Apps come from
  # this flake's modules instead; `when = "false"` hides a row.
  menuExtension = builtins.toJSON {
    install.when = "false";
    remove.when = "false";
    "update.channel".when = "false";
    "update.config".when = "false";
  };
in
{
  config = mkIf enabled {
    home.sessionVariables.OMARCHY_PATH = omarchyPath;

    xdg.configFile = {
      "hypr/bindings.lua".text = bindingsLua;
      "omarchy/extensions/omarchy-menu.jsonc".text = menuExtension;
    };

    # Ghostty follows the Omarchy theme (optional include; absent until set).
    programs.ghostty.settings.config-file = "?${stateDir}/current/theme/ghostty.conf";

    # Omarchy's tools write to these, so they are seeded as real files, never
    # store links, and never overwritten once present.
    home.activation.omarchySeed = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      seed_dir() {
        local src="$1" dest="$2"
        [ -d "$src" ] || return 0
        run mkdir -p "$dest"
        run ${pkgs.coreutils}/bin/cp -r --update=none --no-preserve=mode,ownership \
          "$src"/. "$dest"/
      }

      seed_file() {
        local src="$1" dest="$2"
        [ -f "$src" ] || return 0
        if [ ! -e "$dest" ]; then
          run mkdir -p "$(dirname "$dest")"
          run ${pkgs.coreutils}/bin/cp --no-preserve=mode,ownership "$src" "$dest"
        fi
      }

      for d in omarchy hypr btop imv hyprland-preview-share-picker; do
        seed_dir "${omarchyPath}/config/$d" "${config.xdg.configHome}/$d"
      done

      run mkdir -p "${config.xdg.configHome}/btop/themes" "${stateDir}/current"
      run ln -snf "${stateDir}/current/theme/btop.theme" \
        "${config.xdg.configHome}/btop/themes/current.theme"

      seed_file "${omarchyPath}/default/hypr/toggles/flags.lua" \
        "${stateDir}/toggles/hypr/flags.lua"
      seed_dir "${omarchyPath}/default/tensaku" \
        "${config.home.homeDirectory}/.local/state/tensaku"
      seed_file "${omarchyPath}/icon.txt" "${config.xdg.configHome}/omarchy/branding/about.txt"
      seed_file "${omarchyPath}/logo.txt" "${config.xdg.configHome}/omarchy/branding/screensaver.txt"

      # Default terminal for Omarchy's launchers (xdg-terminal-exec).
      if [ ! -e "${config.xdg.configHome}/xdg-terminals.list" ]; then
        run sh -c 'echo com.mitchellh.ghostty.desktop > "${config.xdg.configHome}/xdg-terminals.list"'
      fi

      # First-run theme; afterwards the Style menu owns it.
      if [ ! -e "${stateDir}/current/theme.name" ]; then
        run env OMARCHY_PATH="${omarchyPath}" OMARCHY_THEME_HEADLESS=1 \
          PATH="${cfg.package}/bin:${lib.makeBinPath cfg.package.passthru.runtimeDeps}:$PATH" \
          ${cfg.package}/bin/omarchy-theme-set "${cfg.theme}" || true
      fi
    '';
  };
}
