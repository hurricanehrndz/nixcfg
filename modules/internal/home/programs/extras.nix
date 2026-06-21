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
  config = mkIf cfg.tooling.extras.enable {
    home.packages = with pkgs; [
      devenv # spin up devenv-based dev environments in other projects
      pandoc
      local.html-to-markdown
      mermaid-cli
    ];
  };
}
