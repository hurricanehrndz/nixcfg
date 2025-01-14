{...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    lib,
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.nixos-install-init = pkgs.callPackage ./tools/nixos-install-init {};
    packages.gpt = pkgs.callPackage ./tools/gpt.nix {};
  };
}
