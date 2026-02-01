{ self, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      zshLib = final.callPackage (self + /per-system/lib/zsh-lib/package.nix) { };
    })
  ];
}
