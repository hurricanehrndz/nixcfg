{
  pkgs,
  lib,
  ...
}:
let
  username = "hurricane";
  homeDir = "/Users/${username}";
in
{
  age = {
    secrets = { };
  };

  # system customization via gated options
  hrndz = {
    roles.developerWorkstation.enable = true;
    roles.vmHost.enable = true;
    tooling.extras.enable = true;
    tooling.js.enable = true;
    tooling.ai.enable = true;
  };

  users.users.${username} = {
    home = homeDir;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users."${username}" = {
    home.stateVersion = "26.05";
  };

  homebrew.casks = [
    "1password"
  ];

  system.primaryUser = "${username}";
  system.stateVersion = lib.mkForce 7;
}
