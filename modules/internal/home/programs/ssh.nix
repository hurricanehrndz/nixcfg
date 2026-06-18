{
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.cli.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "deepthought" = {
          HostName = "172.24.224.15";
          User = "hurricane";
          ForwardAgent = true;
          RemoteForward = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent";
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
              host.address = "/Users/chernand/.gnupg/S.gpg-agent";
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "hal" = {
          HostName = "hal.lan.internal";
          User = "hurricane";
          ForwardAgent = true;
          RemoteForward = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent";
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "dev" = {
          User = "chernand";
          ForwardAgent = true;
          HostName = "cpedev1";
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
          RemoteForward = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
              bind.address = "/run/user/3576/gnupg/S.gpg-agent";
            }
          ];
        };
        "olddev" = {
          User = "chernand";
          HostName = "dev61-uswest1adevc";
          ForwardAgent = true;
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
          RemoteForward = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
              bind.address = "/run/user/3712/gnupg/S.gpg-agent";
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
      };
    };
  };
}
