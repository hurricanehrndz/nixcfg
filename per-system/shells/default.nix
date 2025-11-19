{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];
  perSystem =
    {
      config,
      pkgs,
      self',
      inputs',
      lib,
      ...
    }:
    {
      devshells.default =
        let
          inherit (pkgs.stdenv.hostPlatform) isDarwin;
          treefmt = config.treefmt.build.wrapper;
          nix = inputs'.determinate-nix.packages.default;
          pkgWithCategory = category: package: { inherit package category; };
        in
        {
          name = "default";

          packages =
            with pkgs;
            [
              age
              agenix
              nix
              treefmt
            ]
            ++ (with pkgs.local; [
              strongbox
              strongbox-init
            ])
            ++ (lib.optionals isDarwin [
              inputs'.darwin.packages.darwin-rebuild
            ]);

          commands = with pkgs; [
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
        };
    };
}
