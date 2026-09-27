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

  inherit (osConfig.hrndz.theme.omarchy) theme pin;

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

    -- Mouse wheel scrolls the content, not the viewport (macOS direction).
    -- Here because this is the one Nix-managed file hyprland.lua requires,
    -- and it loads after hypr/input.lua.
    hl.config({ input = { natural_scroll = true } })

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

  # Vendored workspaces widget, installed as a clone of omarchy.workspaces
  # (the shell routes to a clone via omarchy.clonedFrom). Copied in as real
  # files: Omarchy refuses symlinks inside a plugin folder.
  workspacesPluginId = "${config.home.username}.workspaces";
  workspacesPlugin = pkgs.runCommand "omarchy-workspaces-plugin" { } ''
    mkdir -p $out
    substitute ${./omarchy-workspaces/Workspaces.qml} $out/Workspaces.qml \
      --replace-fail '@namedWorkspaces@' '${builtins.toJSON namedWorkspaces}'
    cp ${
      pkgs.writeText "manifest.json" (
        builtins.toJSON {
          schemaVersion = 1;
          id = workspacesPluginId;
          name = "My Workspaces";
          version = "1.0.0";
          author = config.home.username;
          description = "Named (Meh+letter) and numbered workspace indicators";
          kinds = [ "bar-widget" ];
          entryPoints.barWidget = "Workspaces.qml";
          barWidget = {
            displayName = "My Workspaces";
            description = "Named (Meh+letter) and numbered workspace indicators";
            category = "Compositor";
            allowMultiple = false;
          };
          omarchy.clonedFrom = "omarchy.workspaces";
        }
      )
    } $out/manifest.json
  '';

  # Omarchy web-app launchers to drop. A user entry with Hidden=true shadows the
  # package's share/applications file, which launchers treat as deleted.
  hiddenLaunchers = [
    "Basecamp"
    "HEY"
    "Zoom"
  ];

  # Menu rows to hide; `when = "false"` hides a row and everything under it.
  # Install/remove/plugins/extra themes assume pacman or runtime downloads;
  # apps come from this flake's modules instead. Learn is just web links.
  menuExtension = builtins.toJSON {
    install.when = "false";
    remove.when = "false";
    learn.when = "false";
    "setup.plugin.add".when = "false";
    "update.channel".when = "false";
    "update.config".when = "false";
    "update.themes".when = "false";
  };
in
{
  config = mkIf enabled {
    home.sessionVariables.OMARCHY_PATH = omarchyPath;

    # Omarchy sets no cursor theme; Arch's default index.theme supplies one and
    # NixOS has none, so Hyprland would fall back to its built-in cursor.
    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      hyprcursor.enable = true;
    };

    xdg.dataFile = lib.listToAttrs (
      map (name: {
        name = "applications/omarchy-${name}.desktop";
        value.text = ''
          [Desktop Entry]
          Type=Application
          Name=${name}
          Hidden=true
        '';
      }) hiddenLaunchers
    );

    xdg.configFile = {
      "hypr/bindings.lua".text = bindingsLua;
      "omarchy/extensions/omarchy-menu.jsonc".text = menuExtension;
    };

    home.activation.omarchyWorkspacesPlugin = lib.hm.dag.entryAfter [ "omarchySeed" ] ''
      dest="${config.xdg.configHome}/omarchy/plugins/${workspacesPluginId}"
      run rm -rf "$dest"
      run mkdir -p "$dest"
      run ${pkgs.coreutils}/bin/install -m 0644 ${workspacesPlugin}/* "$dest"/

      # A third-party widget is enabled by sitting in the bar layout; swap it in
      # where the built-in sits, as `omarchy plugin clone` does.
      shell_json="${config.xdg.configHome}/omarchy/shell.json"
      if [ -f "$shell_json" ] && ${pkgs.jq}/bin/jq -e '.bar.layout | .. | objects | select(.id? == "omarchy.workspaces")' "$shell_json" >/dev/null 2>&1; then
        if [[ -v DRY_RUN ]]; then
          echo "Would swap omarchy.workspaces for ${workspacesPluginId} in $shell_json"
        else
          ${pkgs.jq}/bin/jq --arg id "${workspacesPluginId}" \
            '.bar.layout |= walk(if type == "object" and .id? == "omarchy.workspaces" then .id = $id else . end)' \
            "$shell_json" > "$shell_json.tmp"
          mv "$shell_json.tmp" "$shell_json"
        fi
      fi
    '';

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

      set_theme() {
        run env OMARCHY_PATH="${omarchyPath}" OMARCHY_THEME_HEADLESS=1 \
          PATH="${cfg.package}/bin:${lib.makeBinPath cfg.package.passthru.runtimeDeps}:$PATH" \
          ${cfg.package}/bin/omarchy-theme-set "$1" || true
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

      # With pin, Nix owns the theme; otherwise it is set on first login only
      # and the Style menu owns it afterwards.
      ${
        if pin then
          ''
            if [ "$(cat "${stateDir}/current/theme.name" 2>/dev/null)" != "${theme}" ]; then
              set_theme "${theme}"
            fi''
        else
          ''
            if [ ! -e "${stateDir}/current/theme.name" ]; then
              set_theme "${theme}"
            fi''
      }
    '';
  };
}
