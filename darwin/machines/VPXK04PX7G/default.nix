{
  pkgs,
  inputs,
  ...
}: let
  username = "chernand";
in {
  users.users.${username} = {
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; developer ++ graphical;
    home.stateVersion = "22.11";
  };

  targets.darwin.defaultsdicts = {
    # Disable Spotlight hotkeys
    "com.apple.symbolichotkeys" = {
      "AppleSymbolicHotKeys" = {
        "64" = {
          enabled = 0;
          value = {
            type = "standard";
            parameters = [
              65535 # no ascii code
              49 # 0x31 space key
              1048576 # command key
            ];
          };
        };
        "65" = {
          enabled = 0;
          value = {
            type = "standard";
            parameters = [
              65535 # no ascii code
              49 # 0x31 space key
              1572864 # command+option
            ];
          };
        };
      };
    };
  };

  system.stateVersion = 4;
}
