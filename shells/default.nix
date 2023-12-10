{
  pkgs,
  inputs,
  flake,
  ...
}: let
  inherit (pkgs) agenix lib;
  inherit (flake.packages) nixos-install-init;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  pkgWithCategory = category: package: {inherit package category;};
in
  pkgs.devshell.mkShell {
    name = "default";
    packages = with pkgs;[
      alejandra
      nixpkgs-fmt
      git-crypt
      nix
    ] ++ (lib.optionals isLinux [ flake.packages.nixos-install-init ]);
    commands = [
      (pkgWithCategory "secrets" agenix)
      {
        name = "format-all";
        category = "general commands";
        help = "Format all nix files in the project";
        command = "alejandra $PRJ_ROOT";
      }
    ] ++ (lib.optionals isLinux [(pkgWithCategory "install" nixos-install-init)]);
  }
