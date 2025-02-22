{
  pkgs,
  lib,
  ...
}: let
  username = "chernand";
  home = "/Users/${username}";
in {
  users.users.${username} = {
    inherit home;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; developer ++ graphical;
    home.stateVersion = "25.05";
  };

  system.stateVersion = lib.mkForce 6;
}
