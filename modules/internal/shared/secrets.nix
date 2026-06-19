{
  self,
  config,
  lib,
  pkgs,
  isBootstrap ? false,
  ...
}:
let
  user = config.system.primaryUser;
  inherit (config.users.users.${user}) home;
  group = if pkgs.stdenv.hostPlatform.isDarwin then "staff" else "users";
in
{
  age.secrets = lib.mkIf (!isBootstrap) {
    "home/zsh/env_vars" = {
      owner = user;
      inherit group;
      file = "${self}/secrets/home/zsh/env_vars.age";
      path = "${home}/.config/zsh/env_vars";
    };
  };
}
