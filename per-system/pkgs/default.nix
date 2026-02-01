{ inputs, self, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
    {
      perSystem.pkgsDirectory = ./by-name;
    }
  ];

  # libraries
  perSystem =
    { pkgs, ... }:
    {
      # Export zshLib in legacyPackages for external users (lib functions, not a derivation)
      # This makes it available as: inputs.hrndz-nixcfg.legacyPackages.<system>.zshLib
      legacyPackages = {
        zshLib = pkgs.callPackage (self + /per-system/lib/zsh-lib/package.nix) { };
      };
    };
}
