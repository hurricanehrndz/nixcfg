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
        # pipx 1.8.0's test fixtures expect the old `name@ url` direct-reference
        # form, but packaging >=25 canonicalizes to `name @ url`, so its test
        # suite fails to build (and thus is never cached). Skip those tests.
        pipx = prev.pipx.overridePythonAttrs (old: {
          disabledTests = (old.disabledTests or [ ]) ++ [
            "test_fix_package_name"
            "test_parse_specifier_for_metadata"
          ];
        });

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
