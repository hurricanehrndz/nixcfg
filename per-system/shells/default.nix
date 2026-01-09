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

          # Override agenix to use rage-with-yubikey
          agenix-rage = pkgs.agenix.override {
            ageBin = "${pkgs.rage-with-yubikey}/bin/rage";
          };
        in
        {
          name = "default";

          packages =
            with pkgs;
            [
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
            (pkgWithCategory "secrets" agenix-rage)
            (pkgWithCategory "secrets" age-plugin-yubikey)
            {
              name = "rage";
              category = "secrets";
              help = "rage (rust version of age) with yubikey plugin";
              package = rage-with-yubikey;
            }
            {
              name = "format-all";
              category = "general commands";
              help = "Format all nix files in the project";
              command = "treefmt";
            }
          ];
        };
    };
}
