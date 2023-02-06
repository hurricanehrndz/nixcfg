{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    # boilerplate - TODO: use
    packages.hello = pkgs.hello;
  };
}
