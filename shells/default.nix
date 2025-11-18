{
  inputs',
  pkgs,
  flake,
  ...
}:
let
  inherit (pkgs) age agenix lib;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  pkgWithCategory = category: package: { inherit package category; };
in
pkgs.devshell.mkShell {
  name = "default";
  packages =
    with pkgs;
    [
      nixfmt-rfc-style
      flake.packages.strongbox
      flake.packages.strongbox-init
      flake.packages.treefmt
      inputs'.determinate-nix.packages.default
    ]
    ++ (lib.optionals isDarwin [
      inputs'.darwin.packages.darwin-rebuild
    ]);
  commands = [
    (pkgWithCategory "secrets" agenix)
    (pkgWithCategory "secrets" age)
    {
      name = "format-all";
      category = "general commands";
      help = "Format all nix files in the project";
      command = "treefmt";
    }
    {
      name = "agenix-rekey";
      category = "secrets";
      help = "Rekey secrets, in secrets directory";
      command = "agenix -i $PRIVATE_KEY -r";
    }
  ];

  devshell.startup.git-config.text = ''
    ${flake.packages.strongbox-init}/bin/strongbox-init
    export PRIVATE_KEY=$HOME/.strongbox_identity
  '';
  devshell.startup.agenix-req.text = ''
    mkdir -p $HOME/.config/zsh
    mkdir -p $HOME/.config/mods
  '';
}
