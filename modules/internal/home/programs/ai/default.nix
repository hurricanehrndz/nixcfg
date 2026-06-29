{
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = osConfig.hrndz;
in
{
  # Terminal AI coding agents, managed for both NixOS and Darwin via
  # home-manager. They come from flake inputs rather than nixpkgs so they
  # track upstream releases closely.
  #
  # pi is managed by its own vendored module (./pi/module.nix) which installs
  # the (wrapped) pi package itself — so it is not listed here.
  config = mkIf cfg.tooling.ai.enable {
    home.packages = [
      inputs.nix-claude-code.packages.${system}.claude
    ]
    # agent-browser drives a real Chrome via CDP; on headless hosts it has no
    # usable browser (and its `install` download won't run on NixOS), so gate
    # it on the GUI role. The pi web extension detects its absence on PATH and
    # disables browser rendering accordingly.
    ++ lib.optional cfg.roles.guiDeveloper.enable pkgs.unstable.agent-browser;
  };
}
