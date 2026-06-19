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
          nix = pkgs.lixPackageSets.stable.lix;
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
              nix-output-monitor
              nvd
              treefmt
            ]
            ++ (with pkgs.local; [
              git-age-filter
            ])
            ++ (lib.optionals isDarwin [
              inputs'.nix-darwin.packages.darwin-rebuild
            ]);

          commands = with pkgs; [
            {
              name = "agenix";
              category = "secrets";
              help = "agenix with the yubikey identity, against working-tree secrets/";
              command = ''
                root=$(${pkgs.git}/bin/git rev-parse --show-toplevel) || exit 1
                # cd "$root/secrets" || exit 1
                exec ${agenix-age}/bin/agenix --identity "$root/identities/age/yubikey-id-5f449e60.txt" "$@"
              '';
            }
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
