{
  pkgs,
  inputs,
  ...
}: let
  username = "carlos";
in {
  users.users.${username} = {
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; developer;
    home.stateVersion = "22.11";
  };

  system.stateVersion = 4;
}
