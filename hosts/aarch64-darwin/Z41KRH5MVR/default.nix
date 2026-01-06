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
    roles.guiDeveloper.enable = true;
    tooling.virtualization.enable = true;
    tooling.macadmin.enable = true;
    tooling.python.enable = true;
    tooling.ruby.enable = true;
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
