{ inputs, ... }:
{
  perSystem =
    ctx@{
      pkgs,
      system,
      lib,
      ...
    }:
    let
      treefmtConfig = {
        runtimeInputs = [ pkgs.nixfmt-rfc-style ];
        settings = {
          on-unmatched = "info";
          formatter.nixfmt = {
            command = "nixfmt";
            includes = [ "*.nix" ];
          };
        };
      };
    in
    {
      _module.args.packages = ctx.config.packages;
      packages.strongbox = pkgs.callPackage ./tools/strongbox.nix { inherit (inputs) strongbox-src; };
      packages.strongbox-init = pkgs.callPackage ./tools/strongbox-init { };
      packages.treefmt = pkgs.treefmt.withConfig treefmtConfig;
    };
}
