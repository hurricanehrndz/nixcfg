{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    controlPersist = "10m";
    controlPath = "~/.ssh/master-%r@%n:%p";
    serverAliveCountMax = 2;
    serverAliveInterval = 300;
    matchBlocks = {
      "lucy" = {
        hostname = "172.28.250.16";
        user = "hurricane";
        forwardAgent = true;
        remoteForwards = [
          {
            host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
          }
        ];
      };
      "deepthought" = {
        hostname = "172.28.250.15";
        user = "hurricane";
        forwardAgent = true;
        remoteForwards = [
          {
            host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
          }
        ];
      };
      "172.28.*" = {
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
        hostname = "dev61-uswest1adevc";
        forwardAgent = true;
        remoteForwards = [
          {
            host.address = "/Users/chernand/.gnupg/S.gpg-agent.extra";
            bind.address = "/run/user/3712/gnupg/S.gpg-agent";
          }
        ];
      };
    };
  };
}
