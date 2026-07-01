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
in
{
  config = mkIf cfg.tooling.ai.enable {
    # User-scope settings: Claude reads this at startup but never writes to
    # it (runtime state — auth, MCP, permission approvals — lives in
    # ~/.claude.json), so a read-only Nix store symlink is safe here.
    home.file.".claude/settings.json".text = builtins.toJSON settings;
  };
}
