{
  lib,
  pkgs,
  runCommand,
}:

lib.makeOverridable (
  { }:
  let
    # Compile all .zsh files in a plugin package
    mkCompiledPlugin =
      {
        plugin,
        name ? plugin.pname or (lib.getName plugin),
      }:
      runCommand "${name}-compiled"
        {
          nativeBuildInputs = [ pkgs.zsh ];
          preferLocalBuild = true;
        }
        ''
          # Copy plugin to output
          cp -r ${plugin} $out
          chmod -R u+w $out

          # Find and compile all .zsh files
          find $out -name "*.zsh" -type f | while read -r zshfile; do
            echo "Compiling: $zshfile"
            zsh -c "zcompile -U \"$zshfile\"" || echo "Warning: failed to compile $zshfile"
          done
        '';

    # Cache and compile command init output
    mkCachedInit =
      {
        name,
        package,
        initArgs ? [ ],
        sanitizedName ? builtins.replaceStrings [ "/" " " ":" ] [ "-" "-" "-" ] name,
      }:
      runCommand "${sanitizedName}-cached-init"
        {
          nativeBuildInputs = [
            pkgs.zsh
            package
          ];
          preferLocalBuild = true;
        }
        ''
          mkdir -p $out/share/zsh-cached-inits/${sanitizedName}

          # Generate the init output
          ${lib.getExe package} ${lib.concatStringsSep " " initArgs} > $out/share/zsh-cached-inits/${sanitizedName}/init.zsh

          # Compile it
          zsh -c "zcompile -UR $out/share/zsh-cached-inits/${sanitizedName}/init.zsh"

          # Create metadata for reference
          cat > $out/share/zsh-cached-inits/${sanitizedName}/meta.txt <<EOF
          package=${package}
          version=${package.version or "unknown"}
          args=${lib.concatStringsSep " " initArgs}
          EOF
        '';
  in
  {
    inherit mkCompiledPlugin mkCachedInit;
  }
) { }
