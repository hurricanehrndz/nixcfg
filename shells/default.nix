{
  pkgs,
  inputs,
}: let
  inherit
    (pkgs)
    agenix
    alejandra
    nixpkgs-fmt
    ;
  pkgWithCategory = category: package: {inherit package category;};
in
  pkgs.devshell.mkShell {
    name = "default";
    packages = [
      alejandra
      nixpkgs-fmt
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
