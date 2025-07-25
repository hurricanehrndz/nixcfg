{
  self,
  pkgs,
  lib,
  ...
}: let
  username = "chernand";
  home = "/Users/${username}";
in {
 age.secrets = let
   owner = "${username}";
   group = "staff";
 in {
   "darwin/aws_auth_config" = {
     inherit owner group;
     file = "${self}/secrets/darwin/aws/auth_config.age";
     path = "${home}/.aws/credentials";
   };
   "darwin/env/zsh_vars" = {
     inherit owner group;
     file = "${self}/secrets/darwin/env/zsh_vars.age";
     path = "${home}/.config/zsh/zsh_vars";
   };
   "darwin/mods/conf.yml" = {
     inherit owner group;
     file = "${self}/secrets/darwin/mods/conf.yml.age";
     path = "${home}/.config/mods/mods.yml";
    };
 };
  users.users.${username} = {
    inherit home;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; developer ++ graphical;
    home.stateVersion = "25.05";
  };

  system.primaryUser = "${username}";
  system.stateVersion = lib.mkForce 6;
}
