{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with import (inputs.darwin + "/modules/launchd/lib.nix") {inherit lib;};
with lib; let
  enabled = pkgs.hostPlatform.isDarwin;
  cfg = config.targets.darwin.defaultsdicts;
  mkActivationCmds = settings: let
    toPretty = attrs: builtins.replaceStrings ["\n"] [""] (pprExpr "" attrs);

    toDefaultsWriteDictCmd = domain: dict: mapAttrsToList (forEachDictInEachDomain domain) dict;

    forEachDictInEachDomain = domain: dict: key: mapAttrsToList (forEachKeyInEachDictInDomain domain dict) key;

    forEachKeyInEachDictInDomain = domain: dict: key: value: ''
      /usr/bin/defaults write ${escapeShellArg domain} ${dict} -dict-add ${key} "${toPretty value}"
    '';

    nonNullDefaults =
      mapAttrs (domain: attrs: (filterAttrs (n: v: v != null) attrs))
      settings;

    writableDefaults =
      filterAttrs (domain: attrs: attrs != {}) nonNullDefaults;
  in
    flatten (mapAttrsToList toDefaultsWriteDictCmd writableDefaults);

  activationCmds = mkActivationCmds cfg;
in {
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
