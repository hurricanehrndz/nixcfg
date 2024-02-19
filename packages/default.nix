{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.nixos-install-init = pkgs.callPackage ./tools/nixos-install-init {};
  };
}
