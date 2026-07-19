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
      permittedInsecurePackages = [
        # Required by Prettier; remove when nixpkgs stops building it with pnpm_9.
        "pnpm-9.15.9"
      ];
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

        # paho-mqtt 2.1.0's test_callback_v2_mqtt3 races on whether the
        # on_disconnect callback fires before its final assertion, so the check
        # phase flakes (and the build is never cached). It's pulled in as a
        # dependency of apprise (agent-notify, snapraid-runner). Deselect the
        # flaky test across every Python package set so apprise builds.
        pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
          (pyfinal: pyprev: {
            paho-mqtt = pyprev.paho-mqtt.overridePythonAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [
                "test_callback_v2_mqtt3"
              ];
            });
          })
        ];

        local = self.packages.${system};
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      })
      # Build the nix-adjacent tooling against Lix rather than CppNix.
      (final: prev: {
        # nix-eval-jobs is built specially in the Lix package set (custom
        # callPackage against lixStdenv) and doesn't reference the top-level
        # name, so it can be inherited directly.
        inherit (prev.lixPackageSets.latest) nix-eval-jobs;

        # nixpkgs-review, nix-fast-build, and colmena are defined in the Lix set
        # as overrides of the top-level packages, so inheriting them would
        # recurse once we shadow those names here. Override the base packages
        # against Lix (and the Lix-built nix-eval-jobs) instead.
        nixpkgs-review = prev.nixpkgs-review.override { nix = prev.lixPackageSets.latest.lix; };
        nix-fast-build = prev.nix-fast-build.override {
          inherit (prev.lixPackageSets.latest) nix-eval-jobs;
        };
        colmena = prev.colmena.override {
          nix = prev.lixPackageSets.latest.lix;
          inherit (prev.lixPackageSets.latest) nix-eval-jobs;
        };
      })
    ];
  };
}
