{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    lib,
    ...
  }: {
    _module.args.packages = ctx.config.packages;
    packages.nixos-install-init = pkgs.callPackage ./tools/nixos-install-init {};
    packages.gpt = pkgs.callPackage ./tools/gpt.nix {};
    packages.strongbox = pkgs.callPackage ./tools/strongbox.nix {inherit (inputs) strongbox-src;};
    packages.strongbox-init = pkgs.callPackage ./tools/strongbox-init {};
    packages.realtek-r8152-driver = pkgs.callPackage ./kernelmodules/realtek-r8152-driver.nix { inherit (inputs) realtek-r8152-src;};
  };
}
