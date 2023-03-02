{ config, lib, pkgs, ... }:

with lib;

let
  enabled = pkgs.hostPlatform.isDarwin;
  cfg = config.targets.darwin.plists;
  mkActivationCmds = settings:
    let
      toPlist = attrs: (lib.generators.toPlist { } attrs);

      toDefaultsWriteDict = domain: key: attrs: ''
        "$DRY_RUN_CMD /usr/bin/defaults write ${
          escapeShellArg domain
          } -dict-add ${key} '<dict>${toPlist attrs}</dict>'"
      '';

      toActivationCmd = domain: attrs: mapAttrsToList (toDefaultsWriteDict domain) attrs;

      nonNullDefaults =
        mapAttrs (domain: attrs: (filterAttrs (n: v: v != null) attrs))
        settings;

      writableDefaults =
        filterAttrs (domain: attrs: attrs != { }) nonNullDefaults;
    in mapAttrsToList toActivationCmd writableDefaults;

  activationCmds = mkActivationCmds cfg;
in
{
  options.targets.darwin.defaultsdicts = mkOption {
    description = "Add dictionary to defaults database for a domain";
    type = types.attrsOf types.attrs;
    default = {};
  };

  config = mkIf (enabled && cfg != {}) {
    system.activationScripts.postUserActivation.text = ''
      ${concatStringsSep "\n" activationCmds}
      $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
