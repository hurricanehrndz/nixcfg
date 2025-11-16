{
  inputs',
  pkgs,
  flake,
  ...
}: let
  inherit (pkgs) age agenix lib;
  inherit (flake.packages) nixos-install-init;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  pkgWithCategory = category: package: {inherit package category;};
in
  pkgs.devshell.mkShell {
    name = "default";
    packages = with pkgs;
      [
        alejandra
        nixpkgs-fmt
        flake.packages.strongbox
        flake.packages.strongbox-init
        inputs'.determinate-nix.packages.default
      ]
      ++ (lib.optionals isLinux [flake.packages.nixos-install-init])
      ++ (lib.optionals isDarwin [
        inputs'.darwin.packages.darwin-rebuild
      ]);
    commands =
      [
        (pkgWithCategory "secrets" agenix)
        (pkgWithCategory "secrets" age)
        {
          name = "format-all";
          category = "general commands";
          help = "Format all nix files in the project";
          command = "alejandra $PRJ_ROOT";
        }
      ]
      ++ (lib.optionals isLinux [(pkgWithCategory "install" nixos-install-init)]);

    devshell.startup.git-config.text = ''
      ${flake.packages.strongbox-init}/bin/strongbox-init
      export PRIVATE_KEY=$HOME/.strongbox_identity
    '';
    devshell.startup.agenix-req.text = ''
      mkdir -p $HOME/.config/zsh
      mkdir -p $HOME/.config/mods
    '';
  }
