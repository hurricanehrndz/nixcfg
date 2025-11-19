inputs: {
  perSystem =
    {
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
          agenix = inputs'.agenix.packages.default;
          pkgWithCategory = category: package: { inherit package category; };
        in
        {
          name = "default";

          packages = [
            pkgs.local.treefmt
            inputs'.determinate-nix.packages.default
          ]
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
