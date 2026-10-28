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
  config = mkIf cfg.tooling.atlassianCli.enable {
    homebrew.taps = [
      {
        name = "pchuri/tap";
        trusted = true;
      }
    ];

    homebrew.brews = [
      "pchuri/tap/confluence-cli"
    ];
  };
}
