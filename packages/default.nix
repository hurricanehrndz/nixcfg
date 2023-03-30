{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    # boilerplate - TODO: use
    packages.swiftformat = pkgs.callPackage ./tools/swiftformat.nix {inherit (inputs) swiftformat-src;};
    packages.swiftlint = pkgs.callPackage ./tools/swiftlint {inherit (inputs) swiftlint-src;};
    packages.hello = pkgs.hello;
  };
}
