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
  # pi is managed by its own module (./pi) via inputs.pi.homeModules.default,
  # which installs the (wrapped) pi package itself — so it is not listed here.
  config = mkIf cfg.tooling.ai.enable {
    home.packages = [
      inputs.nix-claude-code.packages.${system}.claude
      pkgs.unstable.agent-browser # headless browser automation CLI for AI agents
    ];
  };
}
