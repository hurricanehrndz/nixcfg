{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
  isWorkUser = config.home.username == "chernand";
  # Restricted agent socket on the *local* machine, forwarded to remotes.
  # Resolves per-host: /Users/hurricane on muthur, /Users/chernand on the work mac.
  localGpgExtraSocket = "${config.home.homeDirectory}/.gnupg/S.gpg-agent.extra";
in
{
  config = mkIf cfg.roles.terminalUser.enable {
    # devboxctl atomically rewrites its SSH config, so keep its managed blocks
    # in a writable file included by Home Manager's read-only config.
    home.sessionVariables = lib.mkIf isWorkUser {
      DEVBOXCTL_SSH_CONFIG_PATH = "${config.home.homeDirectory}/.ssh/devboxctl_config";
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = lib.optional isWorkUser "~/.ssh/devboxctl_config";
      settings = {
        "deepthought" = {
          HostName = "172.24.224.15";
          User = "hurricane";
          ForwardAgent = true;
          RemoteForward = [
            {
              host.address = localGpgExtraSocket;
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "lucy" = {
          HostName = "lucy.lan.internal";
          User = "hurricane";
          ForwardAgent = true;
          RemoteForward = [
            {
              host.address = localGpgExtraSocket;
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "hal" = {
          HostName = "hal.hrndz.ca";
          User = "hurricane";
          ForwardAgent = true;
          RemoteForward = [
            {
              host.address = localGpgExtraSocket;
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "*.yelpcorp.com" = {
          User = "chernand";
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
        };
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "yes";
          StreamLocalBindUnlink = "yes";
          Compression = false;
          ServerAliveCountMax = 2;
          ServerAliveInterval = 300;
          SetEnv = {
            TERM = "xterm-256color";
          };
        };
      }
      // lib.optionalAttrs isWorkUser {
        "devbox-chernand-main" = {
          User = "chernand";
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
          RemoteForward = [
            {
              host.address = localGpgExtraSocket;
              bind.address = "/run/user/3576/gnupg/S.gpg-agent";
            }
          ];
        };
      };
    };
  };
}
