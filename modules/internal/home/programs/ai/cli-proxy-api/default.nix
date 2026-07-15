{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
  package = pkgs.local.cli-proxy-api;
  configPath = "${config.xdg.configHome}/cli-proxy-api/config.yaml";
  settings = {
    host = "127.0.0.1";
    port = 8317;
    auth-dir = "${config.xdg.dataHome}/cli-proxy-api/auth";

    # This only authenticates localhost clients; upstream OAuth credentials
    # remain writable runtime state under auth-dir.
    api-keys = [ "local" ];

    remote-management = {
      allow-remote = false;
      secret-key = "";
      disable-control-panel = true;
    };
  };
in
{
  config = lib.mkIf cfg.tooling.ai.enable (
    lib.mkMerge [
      {
        home.packages = [ package ];
        xdg.configFile."cli-proxy-api/config.yaml".source =
          (pkgs.formats.yaml { }).generate "cli-proxy-api.yaml"
            settings;
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.cli-proxy-api = {
          Unit.Description = "CLIProxyAPI";
          Service = {
            ExecStart = "${package}/bin/cli-proxy-api -config ${configPath}";
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.cli-proxy-api = {
          enable = true;
          config = {
            ProgramArguments = [
              "${package}/bin/cli-proxy-api"
              "-config"
              configPath
            ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/cli-proxy-api.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/cli-proxy-api.log";
          };
        };
      })
    ]
  );
}
