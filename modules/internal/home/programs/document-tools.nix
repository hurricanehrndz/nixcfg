{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.tooling.documentTools.enable {
    home.packages = with pkgs; [
      pandoc
      local.html-to-markdown
      mermaid-cli
    ];
  };
}
