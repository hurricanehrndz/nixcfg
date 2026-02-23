{
  self,
  self',
  inputs,
  inputs',
  lib,
  config,
  ...
}:
let
  inherit (inputs) import-tree;
in
{
  home-manager = {
    verbose = true;
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "bak";

    extraSpecialArgs = {
      inherit
        self
        self'
        inputs
        inputs'
        ;
    };

    users.${config.system.primaryUser} = {
      home.stateVersion = lib.mkDefault "25.11";
    };

    # Home-manager modules (programs, themes, etc.)
    sharedModules = [
      (import-tree (self + /modules/internal/home))
    ];
  };
}
