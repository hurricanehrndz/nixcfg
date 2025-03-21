{
  self,
  pkgs,
  inputs,
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
  };

  users.users.${username} = {
    inherit home;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; developer ++ graphical;
    home.stateVersion = "22.11";
  };

  system.stateVersion = 4;
}
