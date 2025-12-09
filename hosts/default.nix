{
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) import-tree;
in
{
  imports = [ inputs.easy-hosts.flakeModule ];

  easy-hosts = {
    autoConstruct = true;
    path = ../hosts;

    shared.modules = [
      (import-tree ../modules/internal/shared)
    ];

    perClass = class: {
      modules =
        with inputs;
        builtins.concatLists [
          # darwin modules
          (lib.optionals (class == "darwin") [
            home-manager.darwinModules.home-manager
            determinate.darwinModules.default
            agenix.darwinModules.age
          ])
        ];
    };
  };
}
