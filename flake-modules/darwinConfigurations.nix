{
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      darwinConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated nix-darwin configurations. Used by `darwin-rebuild`.

          `darwinConfigurations` is for specific machines. If you want to expose
          reusable configurations, add them to `darwinModules`
          in the form of modules (no `darwin.lib.darwinSystem`), so that you can reference
          them in this or another flake's `darwinConfigurations`.
        '';
        example = literalExpression ''
          {
            my-machine = inputs.darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = [
                ./my-machine/darwin-configuration.nix
                config.darwinModules.my-module
              ];
            };
          }
        '';
      };
    };
  };
}
