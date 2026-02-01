{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    mkOrder
    concatMapStrings
    ;
  cfg = config.programs.zsh.compiledConfig;
  zshLib = pkgs.zshLib;
in
{
  options.programs.zsh.compiledConfig = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zsh compilation optimizations";
    };

    plugins = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            plugin = mkOption {
              type = types.package;
              description = "The zsh plugin package to compile and load";
            };
            name = mkOption {
              type = types.str;
              default = "";
              description = "Optional name override. If empty, derives from plugin.pname";
            };
            order = mkOption {
              type = types.int;
              default = 500;
              description = ''
                Loading order priority. Lower numbers load first.
                Should typically load before cachedInits (use 100-400 range).
              '';
            };
            defer = mkOption {
              type = types.bool;
              default = false;
              description = "Defer loading of this plugin until after prompt is displayed";
            };
          };
        }
      );
      default = [ ];
      description = "Zsh plugins to compile and load with ordering support";
    };

    cachedInits = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name for the cached init";
            };
            package = mkOption {
              type = types.package;
              description = "Package providing the command";
            };
            initArgs = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Arguments to pass to the command to generate init script";
            };
            order = mkOption {
              type = types.int;
              default = 500;
              description = ''
                Loading order priority. Lower numbers load first.
                Default: 500 (normal priority)
                Suggested ranges:
                  100-199: Critical early initialization
                  200-499: Before normal
                  500: Normal (default)
                  501-799: After normal
                  800-999: Late initialization
              '';
            };
            defer = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Defer loading of this init until after prompt is displayed.
                Useful for non-critical inits to improve perceived startup time.
                Requires zsh-defer to be available.
              '';
            };
          };
        }
      );
      default = [ ];
      description = "Command inits to cache and compile";
    };
  };

  config = mkIf (config.programs.zsh.enable && cfg.enable) {
    # Don't use home-manager's plugin sourcing - we handle it in initContent
    programs.zsh.plugins = [ ];

    # Generate cached init packages and add zsh-defer if needed
    home.packages =
      (map (init: zshLib.mkCachedInit { inherit (init) name package initArgs; }) cfg.cachedInits)
      ++ lib.optional (lib.any (item: item.defer) (cfg.plugins ++ cfg.cachedInits)) pkgs.zsh-defer;

    # Unified loading system for plugins and cachedInits
    programs.zsh.initContent =
      let
        # Convert plugins to common format
        pluginItems = map (p: {
          type = "plugin";
          name = if p.name != "" then p.name else p.plugin.pname or (lib.getName p.plugin);
          order = p.order;
          defer = p.defer;
          package = p.plugin;
        }) cfg.plugins;

        # Convert cachedInits to common format
        initItems = map (i: {
          type = "cachedInit";
          name = i.name;
          order = i.order;
          defer = i.defer;
          package = i.package;
          initArgs = i.initArgs;
        }) cfg.cachedInits;

        # Merge and sort by order
        allItems = lib.sort (a: b: a.order < b.order) (pluginItems ++ initItems);

        # Generate source statements
        generateSource =
          item:
          let
            sanitizedName = builtins.replaceStrings [ "/" " " ":" ] [ "-" "-" "-" ] item.name;
          in
          if item.type == "plugin" then
            let
              compiledPlugin = zshLib.mkCompiledPlugin {
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
            # cachedInit
            let
              sourcePath = "$HOME/.nix-profile/share/zsh-cached-init/${sanitizedName}.zsh";
              sourceCmd = "source \"${sourcePath}\"";
            in
            if item.defer then
              ''
                # Deferred cached init: ${item.name} (order: ${toString item.order})
                [[ -f "${sourcePath}" ]] && zsh-defer ${sourceCmd}
              ''
            else
              ''
                # Cached init: ${item.name} (order: ${toString item.order})
                [[ -f "${sourcePath}" ]] && ${sourceCmd}
              '';

        hasDeferred = lib.any (item: item.defer) allItems;
      in
      mkOrder 500 ''
        ${lib.optionalString hasDeferred ''
          # Load zsh-defer for deferred loading support
          if [[ -f "$HOME/.nix-profile/share/zsh-defer/zsh-defer.plugin.zsh" ]]; then
            source "$HOME/.nix-profile/share/zsh-defer/zsh-defer.plugin.zsh"
          fi
        ''}

        ${concatMapStrings generateSource allItems}
      '';
  };
}
