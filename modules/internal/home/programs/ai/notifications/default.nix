{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
  skill = ./skill;
  notificationSecret = osConfig.age.secrets."home/agent-notifications/config.toml" or null;

  # Work around Apprise's failing optional paho-mqtt check input on Darwin.
  # Remove the override once the nixpkgs package builds there unmodified.
  apprise = pkgs.python3Packages.apprise.overridePythonAttrs (
    _: lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { doCheck = false; }
  );
  pythonNotify = pkgs.writers.writePython3Bin "agent-notify" {
    libraries = [ apprise ];
  } (builtins.readFile ./skill/scripts/agent_notify.py);
  agentNotify =
    if notificationSecret == null then
      pythonNotify
    else
      pkgs.writeShellScriptBin "agent-notify" ''
        exec ${lib.getExe pythonNotify} --config ${lib.escapeShellArg notificationSecret.path} "$@"
      '';
in
{
  config = lib.mkIf cfg.tooling.ai.enable {
    home.packages = [ agentNotify ];

    home.file.".claude/skills/remote-notifications" = {
      source = skill;
      recursive = true;
    };

    programs.codex.skills.remote-notifications = skill;
    programs.pi.coding-agent.skills = [ skill ];

    xdg.configFile."agent-notifications/config.toml.example".source = ./skill/config.toml.example;
  };
}
