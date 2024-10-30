{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    lib,
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.nixos-install-init = pkgs.callPackage ./tools/nixos-install-init {};
    packages.keg = pkgs.buildGoModule {
      name = "keg";
      src = inputs.keg-src;
      vendorHash = "sha256-BYamGc5r31AmoAdVY3c5d4lWh0zljFC1rBZZv6/9PUI="; #lib.fakeHash;
      checkFlags = [
        "-skip=^ExampleDexEntry_Pretty$"
      ];
    };
  };
}
