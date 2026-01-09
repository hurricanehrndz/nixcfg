{ inputs, ... }:
{
  perSystem =
    {
      config,
      system,
      ...
    }:
    {
      # this is what controls how packages in the flake are built, but this is not passed to the
      # builders in lib which is important to note, since we have to do something different for
      # the builders to work correctly
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
        config.permittedInsecurePackages = [
          "aspnetcore-runtime-6.0.36"
          "aspnetcore-runtime-wrapped-6.0.36"
          "dotnet-sdk-6.0.428"
          "dotnet-sdk-wrapped-6.0.428"
        ];
        overlays = [
          inputs.agenix.overlays.default
          inputs.devshell.overlays.default
          # inputs.snapraid-runner.overlays.default

          # Wrap rage with age-plugin-yubikey in PATH and symlink age to rage
          (final: prev: {
            rage-with-yubikey = prev.runCommand "rage-with-yubikey"
              {
                nativeBuildInputs = [ prev.makeWrapper ];
                propagatedBuildInputs = [ prev.rage ];
              }
              ''
                mkdir -p $out/bin
                makeWrapper ${prev.rage}/bin/rage $out/bin/rage \
                  --prefix PATH : "${prev.lib.makeBinPath [ prev.age-plugin-yubikey ]}"
                # Symlink age to rage for compatibility
                ln -s $out/bin/rage $out/bin/age
              ''
              // {
                meta.mainProgram = "rage";
              };
          })

          (final: prev: {
            local = config.packages;
          })
        ];
      };
    };
}
