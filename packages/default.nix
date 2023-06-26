{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.aws-sso = pkgs.callPackage ./aws-sso {};
  };
}
