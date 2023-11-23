{haumea}: let
  # given { a = b; c = { default = d; e = f;}; }
  # return { a = b; c = d };
  squashDefaultVars = attrs:
    with builtins; let
      squashDefault = attr:
        with builtins;
          if isAttrs attr
          then
            if hasAttr "default" attr
            then attr.default
            else mapAttrs (name: value: squashDefault value) attr
          else attr;
    in
      mapAttrs (name: value: squashDefault value) attrs;
in path:
    squashDefaultVars (
      haumea.load {
        src = path;
        loader = haumea.loaders.path;
      }
    )
