{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  config = lib.mkIf cfg.tooling.ai.enable {
    # respec render/serve shell out to hugo; respec doesn't install it.
    home.packages = [ pkgs.hugo ];

    home.activation.respecSkills = lib.hm.dag.entryAfter [ "agentToolkit" ] ''
      for target in pi prime-agent claude codex; do
        $DRY_RUN_CMD "$HOME/.local/bin/respec" install --target "$target"
      done
    '';
  };
}
