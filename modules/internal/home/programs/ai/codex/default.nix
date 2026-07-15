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
      package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      context = ../claude/CLAUDE.md;
    };
  };
}
