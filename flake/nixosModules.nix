{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) import-tree;
in
{
  flake = {
    nixosModules =
      (builtins.listToAttrs (
        lib.pipe import-tree [
          (
            i:
            i.map (path: {
              name = baseNameOf (dirOf path);
              value = path;
            })
          )
          (i: i.withLib lib)
          (i: i.leafs ../modules/exported/nixos)
        ]
      ))
      // {
        default = import-tree ../modules/exported/nixos;
      };

  };
}
