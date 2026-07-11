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
  # Terminal AI coding agents, managed for both NixOS and Darwin via
  # home-manager.
  #
  # pi is managed by the pi.nix Home Manager module, which installs the
  # wrapped package itself — so it is not listed here.
  config = mkIf cfg.tooling.ai.enable {
    home.packages = [
      pkgs.master.claude-code
    ]
    # agent-browser drives a real Chrome via CDP; on headless hosts it has no
    # usable browser (and its `install` download won't run on NixOS), so gate
    # it on the GUI role. The pi web extension detects its absence on PATH and
    # disables browser rendering accordingly.
    ++ lib.optional cfg.roles.guiDeveloper.enable pkgs.unstable.agent-browser;
  };
}
