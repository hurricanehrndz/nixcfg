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
      inputs.agenix.overlays.default
      inputs.snapraid-runner.overlays.default

      (final: prev: {
        local = self.packages.${system};
        master = inputs.nixpkgs-master.legacyPackages.${system};
        unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
        unstable-weekly = inputs.nixpkgs-unstable-weekly.legacyPackages.${system};
      })
    ];
  };
}
