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
        pr-493140 =
          let
            p = import inputs.pr-493140 {
              inherit system;
              config.allowUnfree = true;
            };
          in
          p
          // {
            recyclarr = p.recyclarr.overrideAttrs (old: rec {
              version = "8.3.2";
              src = p.fetchFromGitHub {
                owner = "recyclarr";
                repo = "recyclarr";
                rev = "v${version}";
                hash = "sha256-UMDe4wljN1LjlpXV+5P3pXYf7vEKLwWYUws1B13scS4=";
              };
            });
          };
      })
    ];
  };
}
