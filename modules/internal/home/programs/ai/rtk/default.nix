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
  #   - Pi: the auto-loaded extension below, which delegates to `rtk rewrite`.
  config = mkIf cfg.tooling.ai.enable {
    home.packages = [ pkgs.unstable.rtk ];

    # Pi auto-discovers extensions under ~/.pi/agent/extensions/, so a managed
    # file is enough — no `pi install` needed.
    home.file.".pi/agent/extensions/rtk.ts".source = ./pi-extension.ts;
  };
}
