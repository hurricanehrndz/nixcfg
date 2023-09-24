{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.aws-sso = pkgs.callPackage ./aws-sso {};
    packages.sonarrv4 = pkgs.callPackage ./sonarrv4 {};
    packages.pdenv = inputs'.pdenv.packages.pdenv;
  };
}
