{
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  home.activation = lib.mkIf cfg.tooling.ai.enable {
    # Validate the complete reconciliation before Pi settings or managed links
    # change. Dirty checkouts stay at their current revision.
    agentToolkitCheckout = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      export PATH="${
        lib.makeBinPath [
          pkgs.git
          pkgs.coreutils
        ]
      }:$PATH"

      repo="$HOME/src/me/agent-toolkit"
      expected_https="https://github.com/hurricanehrndz/agent-toolkit.git"
      expected_ssh="git@github.com:hurricanehrndz/agent-toolkit.git"
      toolkit="$repo/scripts/toolkit-sync.mjs"

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

        ${pkgs.nodejs_24}/bin/node "$toolkit" --dry-run --home "$HOME"
      else
        # During a Home Manager dry-run, the clone is printed rather than
        # performed, so there is no checkout to validate yet.
        echo "agentToolkit: checkout would be validated after clone"
      fi
    '';

    agentToolkitSync = lib.hm.dag.entryAfter [ "agentToolkitCheckout" ] ''
      export PATH="${
        lib.makeBinPath [
          pkgs.git
          pkgs.coreutils
          pkgs.unstable.mise
        ]
      }:$PATH"

      repo="$HOME/src/me/agent-toolkit"
      toolkit="$repo/scripts/toolkit-sync.mjs"

      if [ -f "$toolkit" ]; then
        $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/node "$toolkit" --home "$HOME"
      elif [ -n "''${DRY_RUN_CMD:-}" ] && [ ! -e "$repo" ]; then
        echo "agentToolkit: checkout would be reconciled after clone"
      else
        echo "agentToolkit: $repo is missing the sync wrapper" >&2
        exit 1
      fi
    '';
  };
}
