{
  self,
  self',
  inputs,
  inputs',
  lib,
  config,
  channel,
  channelInputs,
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
    # Overwrite a stale `.bak` instead of aborting activation when one already
    # exists (e.g. a previously hand-managed ~/.claude/settings.json.bak).
    overwriteBackup = true;

    extraSpecialArgs = {
      inherit
        self
        self'
        inputs'
        ;
      inputs = inputs // channelInputs channel;
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
