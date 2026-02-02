{
  pkgs,
  lib ? pkgs.lib,
  zsh ? pkgs.zsh,
  runCommand ? pkgs.runCommand,
  ...
}:
let

  # Converts dotDir to absolute path string
  mkAbsPathStr = dotDir: if lib.hasPrefix "/" dotDir then dotDir else "\${HOME}/${dotDir}";

  # Converts dotDir to relative path string
  mkRelPathStr = dotDir: if lib.hasPrefix "/" dotDir then dotDir else dotDir;

  # Determines plugin directory based on dotDir
  # If dotDir is relative "." (home), plugins go in ~/.zsh/plugins
  # Otherwise plugins go in dotDir/plugins
  mkPluginsDir =
    dotDir:
    let
      absPath = mkAbsPathStr dotDir;
      relPath = mkRelPathStr dotDir;
    in
    absPath + (lib.optionalString (relPath == ".") "/.zsh") + "/plugins";

  # Injects zsh-defer plugin into plugins list if any deferred items exist
  #
  # This is an internal helper that ensures zsh-defer is available and compiled
  # when plugins, cachedInits, or rawScripts use defer=true.
  #
  # Arguments:
  #   plugins - List of plugin records
  #   cachedInits - List of cached init records
  #   rawScripts - List of raw script records
  #
  # Returns:
  #   Plugin list with zsh-defer injected at order 20 if needed
  injectZshDefer =
    {
      plugins ? [ ],
      cachedInits ? [ ],
      rawScripts ? [ ],
    }:
    let
      # Check if we need zsh-defer
      hasDeferred =
        (lib.any (p: p.defer or false) plugins)
        || (lib.any (i: i.defer or false) cachedInits)
        || (lib.any (s: s.defer or false) rawScripts);

      # zsh-defer plugin definition
      zshDeferPlugin = {
        name = "zsh-defer";
        src = pkgs.zsh-defer + "/share/zsh-defer";
        file = "zsh-defer.plugin.zsh";
        order = 20;
        defer = false; # zsh-defer itself should never be deferred
      };
    in
    if hasDeferred then [ zshDeferPlugin ] ++ plugins else plugins;

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
  #   $out/fzl-cached-inits/${sanitizedName}/init.zsh(.zwc)
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
        mkdir -p $out/fzl-cached-inits/${sanitizedName}

        # Generate the init output
        ${lib.getExe package} ${lib.concatStringsSep " " initArgs} > $out/fzl-cached-inits/${sanitizedName}/init.zsh

        # Compile it
        zsh -c "zcompile -UR $out/fzl-cached-inits/${sanitizedName}/init.zsh"

        # Create metadata for reference
        cat > $out/fzl-cached-inits/${sanitizedName}/meta.txt <<EOF
        package=${package}
        version=${package.version or "unknown"}
        args=${lib.concatStringsSep " " initArgs}
        EOF
      '';

  # Generates zsh initialization content from plugins and cached inits
  #
  # Takes lists of plugins and cached inits, sorts them by order, and generates
  # the shell code to source them. Handles deferred loading via zsh-defer for
  # plugins/inits marked with defer=true. Plugins are sourced from dotDir/plugins
  # with fpath setup (never deferred) and optional deferred sourcing.
  #
  # Arguments:
  #   plugins - List of plugin records with attributes:
  #     - src: The plugin derivation or path (home-manager compatible)
  #     - name: Plugin name (required)
  #     - file: File to source within plugin (default: "${name}.plugin.zsh")
  #     - order: Loading order (lower numbers load first)
  #     - defer: Optional boolean, defer only the sourcing with zsh-defer (default: false)
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
  #   dotDir - The zsh dotDir path (e.g., ".config/zsh" or ".")
  #
  # Returns:
  #   A string containing zsh initialization code that sources all plugins
  #   and cached inits in the specified order
  #
  # Example:
  #   mkInitContent {
  #     plugins = [
  #       { name = "my-plugin"; src = ./plugin; file = "init.zsh"; order = 100; }
  #       { name = "zsh-autosuggestions"; src = pkgs.zsh-autosuggestions; order = 200; defer = true; }
  #     ];
  #     cachedInits = [
  #       { name = "starship"; package = pkgs.starship; initArgs = ["init" "zsh"]; order = 50; }
  #     ];
  #     rawScripts = [
  #       { content = "export FOO=bar"; name = "env-vars"; order = 10; }
  #     ];
  #     dotDir = ".config/zsh";
  #   }
  mkInitContent =
    {
      plugins ? [ ],
      cachedInits ? [ ],
      rawScripts ? [ ],
      dotDir,
    }:
    let
      # Inject zsh-defer plugin if any items are deferred
      effectivePlugins = injectZshDefer {
        inherit plugins cachedInits rawScripts;
      };

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
        name = if p.name != "" then p.name else (p.src.name or p.src.pname or (lib.getName p.src));
        order = p.order;
        defer = p.defer or false;
        src = p.src;
        file = p.file or "${p.name}.plugin.zsh"; # Default to home-manager convention
      }) effectivePlugins;

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
            pluginsDir = mkPluginsDir dotDir;
            pluginPath = "${pluginsDir}/${item.name}";
            pluginFile = "${pluginPath}/${item.file}";

            # Generate fpath additions (NEVER deferred)
            # Note: This sources from dotDir, not store, so plugins must be copied via mkPluginFiles
            fpathScript = ''
              # Plugin: ${item.name} - fpath setup (order: ${toString item.order})
              fpath+=("${pluginPath}")
            '';

          in
          # fpath always runs immediately, only sourcing can be deferred
          if item.defer then
            fpathScript
            + ''

              # Deferred plugin source: ${item.name}
              [[ -f "${pluginFile}" ]] && zsh-defer source "${pluginFile}"
            ''
          else
            fpathScript
            + ''

              # Plugin source: ${item.name}
              [[ -f "${pluginFile}" ]] && source "${pluginFile}"
            ''
        else if item.type == "cachedInit" then
          # cachedInit - use direct store path reference
          let
            initPath = "${item.derivation}/fzl-cached-inits/${item.sanitizedName}/init.zsh";
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
    in
    ''
      ${lib.concatMapStrings generateSource allItems}
    '';

  # Generates home.file entries to copy plugins to dotDir/plugins
  #
  # Takes a list of plugins and copies them to the zsh plugins directory
  # determined by dotDir configuration. Plugins are compiled before copying.
  # Automatically injects zsh-defer plugin if any deferred items exist.
  #
  # Arguments:
  #   plugins - List of plugin records (see mkInitContent)
  #   cachedInits - Optional list of cached init records (for defer detection)
  #   rawScripts - Optional list of raw script records (for defer detection)
  #   dotDir - The zsh dotDir path (e.g., ".config/zsh" or ".")
  #
  # Returns:
  #   Attribute set suitable for home.file with plugin paths as keys
  #
  # Example:
  #   mkPluginFiles {
  #     plugins = [
  #       { name = "my-plugin"; src = ./plugin; file = "init.zsh"; order = 100; }
  #     ];
  #     dotDir = ".config/zsh";
  #   }
  #   # Returns: { ".config/zsh/plugins/my-plugin".source = <compiled-plugin-drv>; }
  mkPluginFiles =
    {
      plugins ? [ ],
      cachedInits ? [ ],
      rawScripts ? [ ],
      dotDir,
    }:
    let
      # Inject zsh-defer plugin if any items are deferred
      effectivePlugins = injectZshDefer {
        inherit plugins cachedInits rawScripts;
      };

      pluginsDir =
        mkRelPathStr dotDir + (lib.optionalString (mkRelPathStr dotDir == ".") "/.zsh") + "/plugins";
    in
    lib.foldl' (a: b: a // b) { } (
      map (plugin: {
        "${pluginsDir}/${plugin.name}".source = mkCompiledPlugin {
          plugin = plugin.src;
          name = plugin.name;
        };
      }) effectivePlugins
    );

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

          # Import _opts.nix if it exists, otherwise use empty set
          opts = if builtins.pathExists optsFile then import optsFile else { };
        in
        if builtins.pathExists initFile then
          {
            name = fullName;
            src = pluginDir; # Changed from 'plugin'
            file = "init.zsh"; # NEW: explicit file attribute
          }
          // opts # Merge order, defer, and any other options from _opts.nix
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
    mkPluginsFromDir
    mkPluginFiles
    ;
}
