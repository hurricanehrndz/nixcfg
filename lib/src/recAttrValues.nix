{ inputs, ...}:
with builtins; let
  inherit (inputs.nixpkgs) lib;
  _recAttrValues = value:
    if isAttrs value
    then concatMap _recAttrValues (lib.attrValues value)
    else [value];
in
  attrs: concatMap _recAttrValues (lib.attrValues attrs)
