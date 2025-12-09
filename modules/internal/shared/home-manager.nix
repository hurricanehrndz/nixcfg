{
  self,
  self',
  inputs,
  inputs',
  ...
}: let
  inherit (inputs) import-tree;
in {
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

    # Home-manager modules (programs, themes, etc.)
    sharedModules = [ (import-tree (self + /modules/internal/home)) ];
  };
}
