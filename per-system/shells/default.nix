{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];
  perSystem =
    {
      config,
      pkgs,
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

          # Override agenix to use age with age-plugin-yubikey
          agenix-age = pkgs.agenix.override {
            ageBin = "PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]} ${pkgs.age}/bin/age";
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
              git-age-filter
              strongbox
              strongbox-init
            ])
            ++ (lib.optionals isDarwin [
              inputs'.darwin.packages.darwin-rebuild
            ]);

          commands = with pkgs; [
            (pkgWithCategory "secrets" agenix-age)
            (pkgWithCategory "secrets" age)
            (pkgWithCategory "secrets" age-plugin-yubikey)
            (pkgWithCategory "shortcuts" just)
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
