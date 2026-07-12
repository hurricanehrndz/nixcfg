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
    roles.developerWorkstation.enable = true;
    roles.swiftDeveloper.enable = true;
    roles.vmHost.enable = true;
    tooling.macAdmin.enable = true;
    tooling.python.enable = true;
    tooling.ruby.enable = true;
    tooling.js.enable = true;
    tooling.ai.enable = true;
  };

  users.users.${username} = {
    home = homeDir;
    isHidden = false;
    shell = pkgs.zsh;
  };

  system.primaryUser = "${username}";
  system.stateVersion = lib.mkForce 6;
}
