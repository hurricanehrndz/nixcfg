{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = osConfig.hrndz;
  respec = pkgs.local.respec;
in
{
  config = lib.mkIf cfg.tooling.ai.enable {
    home.packages = [ respec ];

    home.activation.respecSkills = lib.hm.dag.entryAfter [ "agentToolkit" ] ''
      for target in pi prime-agent claude codex; do
        $DRY_RUN_CMD ${respec}/bin/respec install --target "$target"
      done
    '';
  };
}
