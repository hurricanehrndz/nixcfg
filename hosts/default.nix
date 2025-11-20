{
  self,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.easy-hosts.flakeModule ];

  easy-hosts = {
    autoConstruct = true;
    path = ../hosts;

    shared.modules = [
    ];

    perClass = class: {

      modules =
        with inputs;
        builtins.concatList [

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
