{
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  config = lib.mkIf cfg.tooling.ai.enable {
    home.activation.respecSkills = lib.hm.dag.entryAfter [ "agentToolkit" ] ''
      for target in pi prime-agent claude codex; do
        $DRY_RUN_CMD "$HOME/.local/bin/respec" install --target "$target"
      done
    '';
  };
}
