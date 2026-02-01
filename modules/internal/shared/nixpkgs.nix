{ config, self, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      (final: prev: {
        local = config.packages;
        # zshLib is a library, not a package, so we keep it in the overlay
        zshLib = final.callPackage (self + /per-system/lib/zsh-lib/package.nix) { };
      })
    ];
  };
}
