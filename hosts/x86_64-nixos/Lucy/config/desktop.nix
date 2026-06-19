{ ... }:
{
  hrndz.desktop.hyprland = {
    autologin = {
      enable = true;
      user = "hurricane";
    };

    remote = {
      enable = true;
      bind = "127.0.0.1";
      port = 5900;
    };

    terminal = "ghostty";
    launcher = "rofi -show drun";

    theme = {
      source = "omarchy";
      variant = "light";
    };
  };
}
