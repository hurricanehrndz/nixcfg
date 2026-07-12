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
      };
  };

  # system customization via gated options
  hrndz = {
    roles.guiDeveloper.enable = true;
    roles.swiftDeveloper.enable = true;
    roles.vmHost.enable = true;
    tooling.macadmin.enable = true;
    tooling.python.enable = true;
    tooling.ruby.enable = true;
    tooling.golang.enable = true;
    tooling.extras.enable = true;
    tooling.js.enable = true;
    tooling.ai.enable = true;
    tooling.ai.localInference.enable = true;
  };

  users.users.${username} = {
    home = homeDir;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users."${username}" = {
    home.stateVersion = "26.05";
  };

  system.primaryUser = "${username}";
  system.stateVersion = lib.mkForce 7;
}
