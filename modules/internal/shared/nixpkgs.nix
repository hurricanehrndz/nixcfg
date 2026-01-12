{ config, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      (final: prev: {
        local = config.packages;
      })
      (final: prev: {
        rage-with-yubikey =
          prev.runCommand "rage-with-yubikey"
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
    ];
  };
}
