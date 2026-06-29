{
  inputs,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  # pi terminal coding agent, managed via the upstream home-manager module
  # (inputs.pi) rather than a bare package so extensions, skills, prompts,
  # themes and settings can be wired declaratively. The module installs its
  # own (wrapped) pi package, so nothing is added to home.packages here.
  #
  # The wrapper only *adds* CLI flags; pi still auto-discovers anything under
  # ~/.pi/agent. Extensions (e.g. rtk's) are contributed to the
  # programs.pi.coding-agent.extensions option from their owning modules.
  #
  # NOTE: skills/promptTemplates/themes are intentionally left unset for now.
  # They'll be wired from pi-ext selectively (work vs. personal) in a later
  # pass — we don't want to mirror everything.
  imports = [ inputs.pi.homeModules.default ];

  programs.pi.coding-agent.enable = cfg.tooling.ai.enable;

  # Ensure my personal pi-ext bundle is checked out for development and
  # registered as a local pi package. This edits ~/.pi/agent/settings.json
  # imperatively rather than via programs.pi.coding-agent.settings: that option
  # would turn the (pi-owned) file into a read-only store symlink and stomp pi's
  # `packages` array. The jq merge only *adds* the entry when missing, so it
  # never reorders the array, never rewrites on a no-op switch, and never
  # clobbers invalid JSON.
  home.activation.piExtRepo = lib.mkIf cfg.tooling.ai.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${
        lib.makeBinPath [
          pkgs.git
          pkgs.jq
          pkgs.coreutils
        ]
      }:$PATH"

      repo="$HOME/src/me/pi-ext"
      settings="$HOME/.pi/agent/settings.json"

      # Clone once; never touch the working tree afterwards.
      if [ ! -d "$repo/.git" ]; then
        $DRY_RUN_CMD git clone https://github.com/hurricanehrndz/pi-ext.git "$repo"
      fi

      # Register the local package only if it is not already listed.
      if [ -e "$settings" ] && jq -e --arg p "$repo" '(.packages // []) | index($p)' "$settings" >/dev/null 2>&1; then
        : # already registered
      else
        $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
        tmp="$(mktemp)"
        ok=0
        if [ -e "$settings" ]; then
          jq --arg p "$repo" '.packages = ((.packages // []) + [$p])' "$settings" > "$tmp" && ok=1
        else
          jq -n --arg p "$repo" '{packages: [$p]}' > "$tmp" && ok=1
        fi
        if [ "$ok" -eq 1 ]; then
          $DRY_RUN_CMD mv "$tmp" "$settings"
        else
          rm -f "$tmp"
          echo "piExtRepo: could not update $settings (invalid JSON?); left unchanged" >&2
        fi
      fi
    ''
  );
}
