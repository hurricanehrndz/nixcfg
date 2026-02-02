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
  config = mkIf cfg.tui.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "deepthought" = {
          hostname = "172.24.224.15";
          user = "hurricane";
          forwardAgent = true;
          remoteForwards = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent";
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "172.24.*" = {
          user = "hurricane";
          forwardAgent = true;
          remoteForwards = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
              bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
        };
        "dev" = {
          user = "chernand";
          forwardAgent = true;
          hostname = "cpedev1";
          userKnownHostsFile = "/dev/null";
          extraOptions = {
            StrictHostKeyChecking = "no";
          };
          remoteForwards = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
              bind.address = "/run/user/3576/gnupg/S.gpg-agent";
            }
          ];
        };
        "olddev" = {
          user = "chernand";
          hostname = "dev61-uswest1adevc";
          forwardAgent = true;
          userKnownHostsFile = "/dev/null";
          extraOptions = {
            StrictHostKeyChecking = "no";
          };
          remoteForwards = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
              bind.address = "/run/user/3712/gnupg/S.gpg-agent";
            }
          ];
        };
        "*.yelpcorp.com" = {
          user = "chernand";
          userKnownHostsFile = "/dev/null";
          extraOptions = {
            StrictHostKeyChecking = "no";
          };
          remoteForwards = [
            {
              host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
              bind.address = "/run/user/3712/gnupg/S.gpg-agent";
            }
          ];
        };
        "*" = {
          setEnv = {
            TERM = "xterm-256color";
          };
          forwardAgent = false;
          addKeysToAgent = "yes";
          compression = false;
          serverAliveCountMax = 2;
          serverAliveInterval = 300;
        };
      };
    };
  };
}
