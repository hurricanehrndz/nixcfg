{
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    services.amethyst.enable = true;
    services.amethyst.settings = {
      layouts = [
        "tall"
        "middle-wide"
        "fullscreen"
      ];
      select-tall-layout = {
        mod = "mod1";
        key = "a";
      };
      toggle-float = {
        mod = "mod1";
        key = "r";
      };
      select-middle-wide-layout = {
        mod = "mod1";
        key = "s";
      };
      select-fullscreen-layout = {
        mod = "mod1";
        key = "t";
      };
      # disabled keys
      select-wide-layout = {
        mod = "mod4";
        key = "s";
      };
      select-column-layout = {
        mod = "mod4";
        key = "t";
      };
      focus-screen-1 = {
        mod = "mod4";
        key = "w";
      };
      focus-screen-2 =  {
        mod = "mod4";
        key = "f";
      };
      focus-screen-3 = {
        mod = "mod4";
        key = "p";
      };
      focus-screen-4 = {
        mod = "mod4";
        key = "q";
      };
      throw-screen-1 = {
        mod = "mod3";
        key = "w";
      };
      throw-screen-2 = {
        mod = "mod4";
        key = "f";
      };
      throw-screen-3 = {
        mod = "mod4";
        key = "p";
      };
      throw-screen-4 = {
        mod = "mod4";
        key = "q";
      };
      window-max-count = 5;
      floating = [
        "com.apple.systempreferences"
        # "com.tinyspeck.slackmacgap"
      ];
    };
  })
]
