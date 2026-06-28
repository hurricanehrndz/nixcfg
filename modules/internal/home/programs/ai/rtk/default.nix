{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  # rtk (Rust Token Killer): a CLI proxy that filters/summarizes command output
  # before it reaches an agent's context, cutting token use 60-90% on common
  # dev commands. Packaged in nixpkgs unstable as `rtk` (github.com/rtk-ai/rtk).
  #
  # The agents wire into it differently:
  #   - Claude Code: a PreToolUse Bash hook (`rtk hook claude`) declared in the
  #     claude module's settings.json.
  #   - Pi: the extension below, wired through the pi module's
  #     programs.pi.coding-agent.extensions option, which delegates to
  #     `rtk rewrite`.
  config = mkIf cfg.tooling.ai.enable {
    home.packages = [ pkgs.unstable.rtk ];

    # Loaded via pi's --extension flag (routed through the pi module option)
    # rather than ~/.pi auto-discovery, so all pi wiring lives in one option.
    programs.pi.coding-agent.extensions = [ ./pi-extension.ts ];
  };
}
