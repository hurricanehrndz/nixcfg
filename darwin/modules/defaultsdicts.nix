{ config, lib, inputs, pkgs, ... }:

with import (inputs.darwin + "/modules/launchd/lib.nix")  { inherit lib; };
with lib;

let
  enabled = pkgs.hostPlatform.isDarwin;
  cfg = config.targets.darwin.defaultsdicts;
  mkActivationCmds = settings:
    let
      toPretty = attrs: builtins.replaceStrings ["\n"] [""] (pprExpr "" attrs);

      toDefaultsWriteDict = domain: key: attrs: ''
        /usr/bin/defaults write ${escapeShellArg domain} AppleSymbolicHotKeys -dict-add ${key} "${toPretty attrs}"
      '';

      toActivationCmd = domain: attrs: mapAttrsToList (toDefaultsWriteDict domain) attrs;

      nonNullDefaults =
        mapAttrs (domain: attrs: (filterAttrs (n: v: v != null) attrs))
        settings;

      writableDefaults =
        filterAttrs (domain: attrs: attrs != { }) nonNullDefaults;
    in flatten (mapAttrsToList toActivationCmd writableDefaults);

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
      # $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
