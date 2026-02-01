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
    homeModules =
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
          (i: i.leafs ../modules/exported/home)
        ]
      ))
      // {
        default = import-tree ../modules/exported/home;
      };
  };
}
