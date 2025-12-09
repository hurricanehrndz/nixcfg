{ config, ... }:
{
  networking = {
    computerName = config.networking.hostName;
    localHostName = config.networking.hostName;
  };
}
