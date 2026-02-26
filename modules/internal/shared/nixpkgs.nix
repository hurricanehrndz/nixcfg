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
        master = import inputs.nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      })
    ];
  };
}
