{ config, ... }:
{
  ##: Hostname
  system.defaults.smb.NetBIOSName = config.networking.hostName;
  system.defaults.smb.ServerDescription = config.networking.hostName;
}
