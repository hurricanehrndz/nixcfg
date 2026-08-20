{
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
  workingStyle = ./AGENTS.md;
in
{
  # Keep one agent-neutral source of personal working preferences and expose it
  # at each agent's global instruction path. These files are read-only
  # configuration, so Nix store symlinks are appropriate.
  config = lib.mkIf cfg.tooling.ai.enable {
    home.file = {
      ".claude/CLAUDE.md".source = workingStyle;
      ".pi/agent/SYSTEM.md".source = workingStyle;
      ".prime/agent/SYSTEM.md".source = workingStyle;
    };

    programs.codex.context = workingStyle;
  };
}
