{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;

  # Run the vendored statusline script from the Nix store with a pinned
  # python3. The script is dependency-free, so no uv/venv is required.
  statusline = "${pkgs.python3}/bin/python3 ${./statusline.py}";

  settings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    includeCoAuthoredBy = false;

    # Light theme + vim keybindings in the input editor.
    # (Shift+Enter for newlines needs no setting here — Ghostty supports it
    # natively. Ctrl+J or `\`+Enter also work in any terminal.)
    theme = "light";
    editorMode = "vim";

    # Nix owns the Claude version (from nixpkgs), so the in-app
    # auto-updater must stay off.
    env.DISABLE_AUTOUPDATER = "1";

    # Lazily load tools instead of injecting every tool definition up front
    # (each can cost ~5-10% of the context window). Mutually exclusive with
    # ENABLE_EXPERIMENTAL_MCP_CLI — only one may be set.
    env.ENABLE_TOOL_SEARCH = "1";

    permissions = {
      # Allow-by-default to minimize prompts: a broad allow auto-approves
      # everything, and the deny list still wins (precedence is deny > ask >
      # allow), so only the genuinely destructive commands are blocked.
      allow = [
        "Bash(*)"
        "Read(*)"
        "Edit(*)"
        "Write(*)"
        "WebFetch(*)"
      ];
      deny = [
        "Bash(sudo:*)"
        "Bash(su:*)"
        "Bash(doas:*)"
        "Bash(mkfs:*)"
        "Bash(mount:*)"
        "Bash(umount:*)"
        "Bash(dd:*)"
        "Bash(shutdown:*)"
        "Bash(reboot:*)"
        "Bash(rm -rf /:*)"
        "Bash(rm -rf ~:*)"
        "Bash(diskutil:*)"
        "Bash(nix-collect-garbage:*)"
      ];
    };

    statusLine = {
      type = "command";
      command = statusline;
    };

    # rtk (Rust Token Killer): rewrite Bash commands through the rtk proxy
    # before they run so their output is token-optimized. The rtk binary is
    # provided by the rtk home module; this hook is a no-op if it is missing.
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];
    };
  };

  settingsFile = pkgs.writeText "claude-settings.json" (builtins.toJSON settings);
in
{
  # Claude DOES write to ~/.claude/settings.json — installing a plugin persists
  # `enabledPlugins` there, and `/config` writes preference changes — so it
  # cannot be a read-only Nix store symlink (that fails with EROFS). Instead of
  # `home.file` (always a store symlink), seed a real, writable file and
  # jq-merge our declarative baseline over it on every switch: the baseline wins
  # on the keys it sets, while runtime-only keys Claude adds (enabledPlugins,
  # marketplaces, /config tweaks) are preserved. Mirrors the ai/pi approach.
  config = mkIf cfg.tooling.ai.enable {
    home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;

    home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${
        lib.makeBinPath [
          pkgs.jq
          pkgs.coreutils
        ]
      }:$PATH"

      settings="$HOME/.claude/settings.json"
      baseline=${settingsFile}

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"

      # Migrate away from the old read-only store symlink, if present.
      if [ -L "$settings" ]; then
        $DRY_RUN_CMD rm -f "$settings"
      fi

      tmp="$(mktemp)"
      ok=0
      if [ -f "$settings" ]; then
        # `.[0] * .[1]`: recursive object merge, baseline (.[1]) wins conflicts;
        # runtime-only keys present only in the existing file survive.
        jq -s '.[0] * .[1]' "$settings" "$baseline" > "$tmp" && ok=1
      else
        cp "$baseline" "$tmp" && ok=1
      fi

      if [ "$ok" -eq 1 ]; then
        # Skip the write (and mtime bump) when nothing changed.
        if [ -f "$settings" ] && cmp -s "$tmp" "$settings"; then
          rm -f "$tmp"
        else
          $DRY_RUN_CMD mv "$tmp" "$settings"
          $DRY_RUN_CMD chmod 600 "$settings"
        fi
      else
        rm -f "$tmp"
        echo "claudeSettings: could not update $settings (invalid JSON?); left unchanged" >&2
      fi
    '';
  };
}
