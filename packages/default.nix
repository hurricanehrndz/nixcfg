{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.sonarrv4 = pkgs.callPackage ./sonarrv4 {};
    packages.nixos-install-init = pkgs.callPackage ./tools/nixos-install-init {};
  };
}
