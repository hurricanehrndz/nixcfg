{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.tooling.documentTools.enable {
    homebrew.taps = [
      {
        name = "1jehuang/mmdr";
        trusted = true;
      }
    ];

    homebrew.brews = [
      "1jehuang/mmdr/mmdr" # fast Mermaid renderer
    ];
  };
}
