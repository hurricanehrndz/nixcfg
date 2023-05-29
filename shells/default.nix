{
  pkgs,
  inputs,
  ...
}: let
  inherit
    (pkgs)
    agenix
    ;
  pkgWithCategory = category: package: {inherit package category;};
in
  pkgs.devshell.mkShell {
    name = "default";
    packages = with pkgs;[
      alejandra
      nixpkgs-fmt
      git-crypt
      nix
      home-manager
    ];
    commands = [
      (pkgWithCategory "secrets" agenix)
      {
        name = "format-all";
        category = "general commands";
        help = "Format all nix files in the project";
        command = "alejandra $PRJ_ROOT";
      }
    ];
  }
