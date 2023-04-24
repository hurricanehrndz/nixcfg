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
        "fullscreen"
      ];
      select-wide-layout = "";
      select-column-layout = "";
      select-fullscreen-layout = {
        mod = "mod1";
        key = "f";
      };
      select-tall-layout = {
        mod = "mod1";
        key = "a";
      };
      focus-screen-1 = "";
      focus-screen-2 = "";
      focus-screen-3 = "";
      focus-screen-4 = "";
      throw-screen-1 = "";
      throw-screen-2 = "";
      throw-screen-3 = "";
      throw-screen-4 = "";
      window-max-count = 3;
      floating = [
        "com.apple.systempreferences"
        "com.tinyspeck.slackmacgap"
      ];
    };
  })
]
