{
  pkgs,
  lib ? pkgs.lib,
  zsh ? pkgs.zsh,
  runCommand ? pkgs.runCommand,
  ...
}:
let

  # Compiles a zsh plugin by running zcompile on all .zsh files
  #
  # Takes a plugin derivation or path and produces a new derivation with all
  # .zsh files compiled to .zwc (zsh word code) format for faster loading.
  #
  # Arguments:
  #   plugin - The plugin derivation or path to compile
  #   name - Optional name for the compiled plugin (defaults to plugin.pname or lib.getName)
  #
  # Returns:
  #   A derivation containing the plugin with compiled .zwc files
  #
  # Example:
  #   mkCompiledPlugin {
  #     plugin = pkgs.zsh-syntax-highlighting;
  #     name = "syntax-highlighting";
  #   }
  mkCompiledPlugin =
    {
      plugin,
      name ? plugin.pname or (lib.getName plugin),
    }:
    runCommand "${name}-compiled"
      {
        nativeBuildInputs = [ zsh ];
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

  # Caches and compiles the output of a command's init script
  #
  # Runs a command (like zoxide, starship, etc.) to generate shell initialization
  # code, saves the output to a file, and compiles it with zcompile for faster
  # loading. Useful for expensive init commands that produce static output.
  #
  # Arguments:
  #   name - Descriptive name for the cached init (e.g., "zoxide", "starship")
  #   package - The package containing the command to run
  #   initArgs - Optional list of arguments to pass to the command (default: [])
  #   sanitizedName - Optional sanitized name for file paths (auto-generated if not provided)
  #
  # Returns:
  #   A derivation containing the cached and compiled init script at
  #   $out/share/zsh/cached-inits/${sanitizedName}/init.zsh(.zwc)
  #
  # Example:
  #   mkCachedInit {
  #     name = "zoxide";
  #     package = pkgs.zoxide;
  #     initArgs = [ "init" "zsh" ];
  #   }
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
          zsh
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

  # Generates zsh initialization content from plugins and cached inits
  #
  # Takes lists of plugins and cached inits, sorts them by order, and generates
  # the shell code to source them. Handles deferred loading via zsh-defer for
  # plugins/inits marked with defer=true. Automatically compiles plugins and
  # uses direct store paths for reliable loading.
  #
  # Arguments:
  #   plugins - List of plugin records with attributes:
  #     - plugin: The plugin derivation or path
  #     - name: Plugin name (defaults to plugin.pname)
  #     - order: Loading order (lower numbers load first)
  #     - defer: Optional boolean, defer loading with zsh-defer (default: false)
  #     - path: Optional relative path within plugin for monolithic plugins (e.g., "zsh-syntax-highlighting.zsh")
  #   cachedInits - List of cached init records with attributes:
  #     - name: Descriptive name
  #     - package: Package containing the command
  #     - initArgs: Arguments to pass to the command
  #     - order: Loading order
  #     - defer: Optional boolean, defer loading (default: false)
  #   rawScripts - List of raw script records with attributes:
  #     - content: The raw zsh script string to include
  #     - name: Optional descriptive name (default: "raw-script")
  #     - order: Loading order (lower numbers load first)
  #     - defer: Optional boolean, defer loading with zsh-defer (default: false)
  #
  # Returns:
  #   A string containing zsh initialization code that sources all plugins
  #   and cached inits in the specified order
  #
  # Example:
  #   mkInitContent {
  #     plugins = [
  #       { plugin = ./my-plugin; name = "my-plugin"; order = 100; }
  #       { plugin = pkgs.zsh-autosuggestions; order = 200; defer = true; }
  #       { plugin = pkgs.zsh-syntax-highlighting; path = "zsh-syntax-highlighting.zsh"; order = 300; }
  #     ];
  #     cachedInits = [
  #       { name = "starship"; package = pkgs.starship; initArgs = ["init" "zsh"]; order = 50; }
  #     ];
  #     rawScripts = [
  #       { content = "export FOO=bar"; name = "env-vars"; order = 10; }
  #     ];
  #   }
  mkInitContent =
    {
      plugins ? [ ],
      cachedInits ? [ ],
      rawScripts ? [ ],
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
        path = p.path or null;
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

      # Convert rawScripts to common format
      rawScriptItems = map (s: {
        type = "rawScript";
        name = s.name or "raw-script";
        order = s.order;
        defer = s.defer or false;
        content = s.content;
      }) rawScripts;

      # Merge and sort by order
      allItems = lib.sort (a: b: a.order < b.order) (pluginItems ++ initItems ++ rawScriptItems);

      # Generate source statements
      generateSource =
        item:
        if item.type == "plugin" then
          let
            compiledPlugin = mkCompiledPlugin {
              plugin = item.package;
              name = item.name;
            };
            # Use explicit path if provided, otherwise find the main init file
            sourceCmd =
              if item.path != null then
                ''[[ -f "${compiledPlugin}/${item.path}" ]] && source "${compiledPlugin}/${item.path}"''
              else
                ''
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
        else if item.type == "cachedInit" then
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
            ''
        else
        # rawScript - inline the content
        if item.defer then
          ''
            # Deferred: ${item.name} (order: ${toString item.order})
            zsh-defer eval ${lib.escapeShellArg item.content}
          ''
        else
          ''
            # ${item.name} (order: ${toString item.order})
            ${item.content}
          '';

      hasDeferred = lib.any (item: item.defer) allItems;
    in
    ''
      ${lib.optionalString hasDeferred ''
        # Built with fast-zsh-init

        # Load zsh-defer - direct store path
        if [[ -f "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh" ]]; then
          source "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh"
        fi
      ''}

      ${lib.concatMapStrings generateSource allItems}
    '';

  # Collects all package derivations needed for a zsh configuration
  #
  # Gathers the cached init derivations and conditionally includes zsh-defer
  # if any plugins or cached inits use deferred loading. These packages should
  # be added to the system or home-manager environment.
  #
  # Arguments:
  #   cachedInits - List of cached init records (see mkInitContent)
  #   plugins - List of plugin records (see mkInitContent)
  #
  # Returns:
  #   A list of derivations to include in the environment
  #
  # Example:
  #   mkPackages {
  #     cachedInits = [
  #       { name = "zoxide"; package = pkgs.zoxide; initArgs = ["init" "zsh"]; }
  #     ];
  #     plugins = [
  #       { plugin = pkgs.zsh-autosuggestions; defer = true; }
  #     ];
  #   }
  #   # Returns: [ <zoxide-cached-init-drv> pkgs.zsh-defer ]
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

  # Creates plugin records from a directory structure
  #
  # Scans a directory for subdirectories containing init.zsh files and converts
  # them into plugin records suitable for mkInitContent. Each subdirectory can
  # optionally include a _default.nix file with configuration options.
  #
  # Arguments:
  #   dir - Path to directory containing plugin subdirectories
  #   namePrefix - Optional prefix to add to all plugin names (default: "")
  #
  # Expected directory structure:
  #   dir/
  #     plugin-name/
  #       init.zsh        # Required: plugin initialization code
  #       _default.nix    # Optional: { order = 100; defer = false; }
  #
  # Returns:
  #   List of plugin records with attributes: name, plugin, order?, defer?
  #
  # Example:
  #   mkPluginsFromDir {
  #     dir = ./zsh/plugins;
  #     namePrefix = "custom";
  #   }
  #   # Returns: [
  #   #   { name = "custom-aliases"; plugin = ./zsh/plugins/aliases; order = 100; }
  #   #   { name = "custom-utils"; plugin = ./zsh/plugins/utils; order = 200; }
  #   # ]
  mkPluginsFromDir =
    {
      dir,
      namePrefix ? "",
    }:
    let
      # Read directory entries
      entries = builtins.readDir dir;

      # Filter for directories only
      subdirs = lib.filterAttrs (name: type: type == "directory") entries;

      # Build a plugin record for each subdirectory that contains init.zsh
      mkPluginFromSubdir =
        name:
        let
          pluginDir = dir + "/${name}";
          initFile = pluginDir + "/init.zsh";
          optsFile = pluginDir + "/_opts.nix";
          fullName = if namePrefix != "" then "${namePrefix}-${name}" else name;

          # Import _default.nix if it exists, otherwise use empty set
          opts = if builtins.pathExists optsFile then import optsFile else { };
        in
        if builtins.pathExists initFile then
          {
            name = fullName;
            plugin = pluginDir;
          }
          // opts # Merge order, defer, and any other options from _default.nix
        else
          null;

      # Map over subdirs and filter out nulls
      plugins = lib.filter (x: x != null) (map mkPluginFromSubdir (lib.attrNames subdirs));
    in
    plugins;
in
{
  inherit
    mkCompiledPlugin
    mkCachedInit
    mkInitContent
    mkPackages
    mkPluginsFromDir
    ;
}
