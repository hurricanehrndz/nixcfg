{
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  config = lib.mkIf cfg.tooling.ai.enable {
    programs.codex = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
      context = ../claude/CLAUDE.md;
    };
  };
}
