{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) import-tree;
in
{
  flake = {
    darwinModules =
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
          (i: i.leafs ./modules/exported/darwin)
        ]
      ))
      // {
        default = import-tree (self + /modules/exported/darwin);
      };

  };
}
