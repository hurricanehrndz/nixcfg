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

  # Ensure my personal pi-ext bundle is checked out for development and keep a
  # set of pi packages registered (the local pi-ext checkout plus remote
  # bundles). This edits ~/.pi/agent/settings.json imperatively rather than via
  # programs.pi.coding-agent.settings: that option would turn the (pi-owned)
  # file into a read-only store symlink and stomp pi's `packages` array. The jq
  # merge only *appends* missing entries (order is irrelevant to pi), so it
  # never rewrites on a no-op switch and never clobbers invalid JSON.
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

      # Packages to keep registered: local pi-ext checkout plus remote bundles.
      want=(
        "$repo"
        "git:github.com/otahontas/pi-coding-agent-catppuccin"
      )
      wantjson="$(jq -n '$ARGS.positional' --args "''${want[@]}")"

      # Append any desired entry that is not already listed.
      if [ -e "$settings" ] && jq -e --argjson want "$wantjson" '(.packages // []) as $cur | all($want[]; . as $x | $cur | index($x))' "$settings" >/dev/null 2>&1; then
        : # all registered
      else
        $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
        tmp="$(mktemp)"
        ok=0
        if [ -e "$settings" ]; then
          jq --argjson want "$wantjson" '.packages = ((.packages // []) as $cur | $cur + [ $want[] | select(. as $x | ($cur | index($x)) == null) ])' "$settings" > "$tmp" && ok=1
        else
          jq -n --argjson want "$wantjson" '{packages: $want}' > "$tmp" && ok=1
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
