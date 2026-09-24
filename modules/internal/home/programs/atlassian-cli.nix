{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  config = lib.mkIf cfg.tooling.atlassianCli.enable {
    home.packages = with pkgs; [
      jira-cli-go
      local.confluence-cli
    ];
  };
}
