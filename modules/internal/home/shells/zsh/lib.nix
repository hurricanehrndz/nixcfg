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
      type = types.listOf types.package;
      default = [ ];
      description = "Zsh plugins to compile. These will be automatically processed with mkCompiledPlugin.";
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
          };
        }
      );
      default = [ ];
      description = "Command inits to cache and compile";
    };
  };

  config = mkIf (config.programs.zsh.enable && cfg.enable) {
    # Compile specified plugins
    programs.zsh.plugins = map (plugin: {
      name = plugin.pname or (lib.getName plugin);
      src = zshLib.mkCompiledPlugin { inherit plugin; };
    }) cfg.plugins;

    # Generate cached init packages
    home.packages = map (
      init: zshLib.mkCachedInit { inherit (init) name package initArgs; }
    ) cfg.cachedInits;

    # Source cached inits in zsh config
    programs.zsh.initContent = concatMapStrings (
      init:
      let
        sanitizedName = builtins.replaceStrings [ "/" " " ":" ] [ "-" "-" "-" ] init.name;
      in
      ''
        # Cached init for ${init.name}
        [[ -f "$HOME/.nix-profile/share/zsh-cached-init/${sanitizedName}.zsh" ]] && \
          source "$HOME/.nix-profile/share/zsh-cached-init/${sanitizedName}.zsh"
      ''
    ) cfg.cachedInits;
  };
}
