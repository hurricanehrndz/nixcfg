{
  lib,
  pkgs,
  runCommand,
  ...
}:
let

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
        mkdir -p $out/share/zsh/cached-inits/${sanitizedName}

        # Generate the init output
        ${lib.getExe package} ${lib.concatStringsSep " " initArgs} > $out/share/zsh/cached-inits/${sanitizedName}/init.zsh

        # Compile it
        zsh -c "zcompile -UR $out/share/zsh/cached-inits/${sanitizedName}/init.zsh"

        # Create metadata for reference
        cat > $out/share/zsh/cached-inits/${sanitizedName}/meta.txt <<EOF
        package=${package}
        version=${package.version or "unknown"}
        args=${lib.concatStringsSep " " initArgs}
        EOF
      '';
  mkInitContent =
    {
      plugins ? [ ],
      cachedInits ? [ ],
    }:
    let
      # Generate cached init derivations with metadata
      cachedInitDerivations = map (init: {
        inherit (init) name order;
        defer = init.defer or false;
        sanitizedName = builtins.replaceStrings [ "/" " " ":" ] [ "-" "-" "-" ] init.name;
        derivation = mkCachedInit { inherit (init) name package initArgs; };
      }) cachedInits;

      # Convert plugins to common format
      pluginItems = map (p: {
        type = "plugin";
        name = if p.name != "" then p.name else p.plugin.pname or (lib.getName p.plugin);
        order = p.order;
        defer = p.defer or false;
        package = p.plugin;
      }) plugins;

      # Convert cachedInits to common format with derivation references
      initItems = map (i: {
        type = "cachedInit";
        inherit (i)
          name
          order
          defer
          derivation
          sanitizedName
          ;
      }) cachedInitDerivations;

      # Merge and sort by order
      allItems = lib.sort (a: b: a.order < b.order) (pluginItems ++ initItems);

      # Generate source statements
      generateSource =
        item:
        if item.type == "plugin" then
          let
            compiledPlugin = mkCompiledPlugin {
              plugin = item.package;
              name = item.name;
            };
            # Find the main init file (common patterns: *.plugin.zsh, init.zsh, *.zsh)
            sourceCmd = ''
              for initfile in "${compiledPlugin}"/*.plugin.zsh "${compiledPlugin}"/init.zsh "${compiledPlugin}"/*.zsh; do
                [[ -f "$initfile" ]] && source "$initfile" && break
              done
            '';
          in
          if item.defer then
            ''
              # Deferred plugin: ${item.name} (order: ${toString item.order})
              zsh-defer ${sourceCmd}
            ''
          else
            ''
              # Plugin: ${item.name} (order: ${toString item.order})
              ${sourceCmd}
            ''
        else
          # cachedInit - use direct store path reference
          let
            initPath = "${item.derivation}/share/zsh/cached-inits/${item.sanitizedName}/init.zsh";
          in
          if item.defer then
            ''
              # Deferred: ${item.name} (order: ${toString item.order})
              [[ -f "${initPath}" ]] && zsh-defer source "${initPath}"
            ''
          else
            ''
              # ${item.name} (order: ${toString item.order})
              [[ -f "${initPath}" ]] && source "${initPath}"
            '';

      hasDeferred = lib.any (item: item.defer) allItems;
    in
    ''
      ${lib.optionalString hasDeferred ''
        # Load zsh-defer - direct store path
        if [[ -f "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh" ]]; then
          source "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh"
        fi
      ''}

      ${lib.concatMapStrings generateSource allItems}
    '';

  # Get packages needed for the configuration
  mkPackages =
    {
      cachedInits ? [ ],
      plugins ? [ ],
    }:
    let
      cachedInitDerivations = map (
        init: mkCachedInit { inherit (init) name package initArgs; }
      ) cachedInits;
      hasDeferred = lib.any (item: item.defer or false) (plugins ++ cachedInits);
    in
    cachedInitDerivations ++ lib.optional hasDeferred pkgs.zsh-defer;
in
{
  inherit
    mkCompiledPlugin
    mkCachedInit
    mkInitContent
    mkPackages
    ;
}
