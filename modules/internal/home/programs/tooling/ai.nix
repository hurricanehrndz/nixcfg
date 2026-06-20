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
  # home-manager. Both come from flake inputs rather than nixpkgs so they
  # track upstream releases closely.
  config = mkIf cfg.roles.terminalDeveloper.enable {
    home.packages = [
      inputs.nix-claude-code.packages.${system}.claude
      inputs.pi.packages.${system}.default
    ];
  };
}
