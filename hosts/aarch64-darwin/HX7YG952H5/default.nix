{
  pkgs,
  lib,
  ...
}:
let
  username = "chernand";
  homeDir = "/Users/${username}";
in
{
  # system customization via gated options
  hrndz = {
    core.enable = true;
  };

  users.users.${username} = {
    home = homeDir;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = {
    home.stateVersion = "25.05";
  };

  system.primaryUser = "${username}";
  system.stateVersion = lib.mkForce 6;
}
