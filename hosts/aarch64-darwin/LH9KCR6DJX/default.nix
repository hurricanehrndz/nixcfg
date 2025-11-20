{ pkgs, lib, ... }:
let
  username = "chernand";
  homeDir = "/Users/${username}";
in
{
  easy-hosts.host.class = "darwin";

  users.users.${username} = {
    home = homeDir;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    home.stateVersion = "25.05";
  };

  system.primaryUser = "${username}";
  system.stateVersion = lib.mkForce 6;
}
