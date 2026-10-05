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

  # Pi owns settings.json at runtime. Nix narrowly ensures the package entries
  # required on every AI-enabled host, preserves all other settings/packages,
  # and removes only the exact legacy ~/src/me/pi-ext entry.
  home.activation.piAgentToolkitSettings = lib.mkIf cfg.tooling.ai.enable (
    lib.hm.dag.entryBetween [ "agentToolkitSync" ] [ "agentToolkitCheckout" ] ''
      export PATH="${
        lib.makeBinPath [
          pkgs.jq
          pkgs.coreutils
        ]
      }:$PATH"

      repo="$HOME/src/me/agent-toolkit"
      legacy_repo="$HOME/src/me/pi-ext"
      settings="$HOME/.pi/agent/settings.json"

      if [ -L "$settings" ]; then
        echo "piAgentToolkitSettings: $settings is a symlink; refusing to replace it" >&2
        exit 1
      fi
      if [ -e "$settings" ] && [ ! -f "$settings" ]; then
        echo "piAgentToolkitSettings: $settings is not a regular file; left unchanged" >&2
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
        echo "piAgentToolkitSettings: $settings is not strict JSON; left unchanged" >&2
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
    ''
  );
}
