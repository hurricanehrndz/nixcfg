{
  self,
  pkgs,
  lib,
  ...
}:
let
  username = "chernand";
  homeDir = "/Users/${username}";
in
{
  age = {
    ageBin = "PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]} ${pkgs.age}/bin/age";
    secrets =
      let
        owner = "${username}";
        group = "staff";
      in
      {
        "darwin/aws_auth_config" = {
          inherit owner group;
          file = "${self}/secrets/darwin/aws/auth_config.age";
          path = "${homeDir}/.aws/credentials";
        };
        "darwin/env/zsh_vars" = {
          inherit owner group;
          file = "${self}/secrets/darwin/zsh/env_vars.age";
          path = "${homeDir}/.config/zsh/zsh_vars";
        };
      };
  };

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
