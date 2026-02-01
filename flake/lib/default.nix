{ inputs, lib, ... }:
let
  inherit (inputs) import-tree;

  # Transform import-tree leafs into attribute set keyed by filename (without .nix extension)
  # Example: src/fast-zsh-lib.nix -> { fast-zsh-lib = <module>; }
  mkLibs =
    paths:
    builtins.listToAttrs (
      map (path: {
        name = lib.removeSuffix ".nix" (baseNameOf path);
        value = import path;
      }) paths
    );
in
{
  flake = {
    lib = mkLibs (
      lib.pipe import-tree [
        (i: i.withLib lib)
        (i: i.leafs ./src)
      ]
    );
  };
}
