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

  targets.darwin.plists = {
    # Disable Spotlight hotkey
    "Library/Preferences/com.apple.symbolichotkeys.plist" = {
      "AppleSymbolicHotKeys:64:enabled" = false;
    };
  };

  system.stateVersion = 4;
}
