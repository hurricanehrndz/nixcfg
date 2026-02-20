{
  inputs,
  self,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      (final: prev: {
        local = self.packages.${system};
      })
      (final: prev: {
        inherit (prev.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      })
      inputs.snapraid-runner.overlays.default
    ];
  };
}
