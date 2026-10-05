{
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  # The upstream module's wrapper only adds CLI flags; pi still owns
  # ~/.pi/agent/settings.json and auto-discovers anything under ~/.pi/agent.
  # Extensions (e.g. rtk's) are contributed from their owning modules.
  imports = [ inputs.pi.homeModules.default ];

  programs.pi.coding-agent = {
    enable = cfg.tooling.ai.enable;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
  };

  # Bootstrap the personal Agent Toolkit and fast-forward a clean checkout.
  # Dirty checkouts are left at their current revision. The toolkit remains the
  # sole owner of its skill and global-context links and the respec binary; this
  # activation invokes its sync wrapper after Home Manager has updated links for
  # the new generation.
  #
  # pi owns settings.json at runtime. Nix narrowly ensures the package entries
  # required on every AI-enabled host, preserves all other settings/packages,
  # and removes only the exact legacy ~/src/me/pi-ext entry.
  home.activation.agentToolkit = lib.mkIf cfg.tooling.ai.enable (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      export PATH="${
        lib.makeBinPath [
          pkgs.git
          pkgs.jq
          pkgs.coreutils
          pkgs.unstable.mise
        ]
      }:$PATH"

      repo="$HOME/src/me/agent-toolkit"
      legacy_repo="$HOME/src/me/pi-ext"
      settings="$HOME/.pi/agent/settings.json"
      expected_https="https://github.com/hurricanehrndz/agent-toolkit.git"
      expected_ssh="git@github.com:hurricanehrndz/agent-toolkit.git"
      toolkit="$repo/scripts/toolkit-sync.mjs"

      repo_ready=0
      if [ ! -e "$repo" ]; then
        $DRY_RUN_CMD git clone "$expected_https" "$repo"
      fi

      if [ -e "$repo" ]; then
        if [ ! -d "$repo" ] || [ "$(git -C "$repo" rev-parse --is-inside-work-tree 2>/dev/null || true)" != "true" ]; then
          echo "agentToolkit: $repo exists but is not a Git checkout; left unchanged" >&2
          exit 1
        fi
        checkout_root="$(git -C "$repo" rev-parse --show-toplevel)"
        if [ "$(realpath "$checkout_root")" != "$(realpath "$repo")" ]; then
          echo "agentToolkit: $repo is not the checkout root; left unchanged" >&2
          exit 1
        fi

        origin="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
        case "$origin" in
          "$expected_https" | "''${expected_https%.git}" | "$expected_ssh" | "''${expected_ssh%.git}" | "ssh://git@github.com/hurricanehrndz/agent-toolkit.git" | "ssh://git@github.com/hurricanehrndz/agent-toolkit")
            ;;
          *)
            echo "agentToolkit: $repo has unexpected origin '$origin'; left unchanged" >&2
            exit 1
            ;;
        esac

        if [ -z "$(git -C "$repo" status --porcelain=v1)" ]; then
          $DRY_RUN_CMD git -C "$repo" pull --ff-only
        else
          echo "agentToolkit: $repo has local changes; skipping update"
        fi

        if [ ! -f "$toolkit" ] || [ ! -f "$repo/context/working-style.md.j2" ]; then
          echo "agentToolkit: $repo is missing the installer or global context source; update it before activating" >&2
          exit 1
        fi
        repo_ready=1
      else
        # During a Home Manager dry-run, the clone is printed rather than
        # performed, so there is no checkout to validate or reconcile yet.
        echo "agentToolkit: checkout would be reconciled after clone"
      fi

      if [ "$repo_ready" -eq 1 ]; then
        # Preflight the complete reconciliation before changing settings or
        # links. Existing files and links owned by another checkout are errors.
        ${pkgs.nodejs_24}/bin/node "$toolkit" --dry-run --home "$HOME"

        if [ -L "$settings" ]; then
          echo "agentToolkit: $settings is a symlink; refusing to replace it" >&2
          exit 1
        fi
        if [ -e "$settings" ] && [ ! -f "$settings" ]; then
          echo "agentToolkit: $settings is not a regular file; left unchanged" >&2
          exit 1
        fi

        if [ -e "$settings" ] && ! ${pkgs.python3}/bin/python3 -c 'import textwrap; exec(textwrap.dedent("""
          import json
          import sys

          def unique_object(items):
              result = {}
              for key, value in items:
                  if key in result:
                      raise ValueError(f"duplicate object key: {key!r}")
                  result[key] = value
              return result

          def reject_constant(value):
              raise ValueError(f"invalid JSON constant: {value}")

          try:
              with open(sys.argv[1], encoding="utf-8") as source:
                  json.load(source, object_pairs_hook=unique_object, parse_constant=reject_constant)
          except (OSError, UnicodeError, ValueError) as error:
              print(error, file=sys.stderr)
              raise SystemExit(1)
        """))' "$settings"; then
          echo "agentToolkit: $settings is not strict JSON; left unchanged" >&2
          exit 1
        fi

        wantjson="$(
          jq -n '$ARGS.positional' --args \
            "$repo" \
            "git:github.com/otahontas/pi-coding-agent-catppuccin"
        )"
        settings_dir="$(dirname "$settings")"
        if [ -n "''${DRY_RUN_CMD:-}" ]; then
          tmp_template="''${TMPDIR:-/tmp}/agent-toolkit-settings.XXXXXX"
        else
          mkdir -p "$settings_dir"
          tmp_template="$settings_dir/.agent-toolkit-settings.XXXXXX"
        fi

        (
          set -e
          tmp="$(mktemp "$tmp_template")"
          trap 'rm -f "$tmp"' EXIT

          if [ -e "$settings" ]; then
            jq --arg legacy "$legacy_repo" --argjson want "$wantjson" '
              if type != "object" then
                error("top level must be an object")
              elif has("packages") and .packages != null and (.packages | type) != "array" then
                error("packages must be an array")
              else
                (.packages // []) as $current
                | [$current[] | select(. != $legacy)] as $kept
                | .packages = ($kept + [$want[] | select(. as $entry | ($kept | index($entry)) == null)])
              end
            ' "$settings" > "$tmp"
          else
            jq -n --argjson want "$wantjson" '{packages: $want}' > "$tmp"
          fi

          if [ ! -e "$settings" ] || ! cmp -s "$tmp" "$settings"; then
            $DRY_RUN_CMD mv "$tmp" "$settings"
            $DRY_RUN_CMD chmod 600 "$settings"
          fi
        )

        $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/node "$toolkit" --home "$HOME"
      fi
    ''
  );
}
