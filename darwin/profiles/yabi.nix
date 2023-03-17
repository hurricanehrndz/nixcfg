{
  config,
  lib,
  pkgs,
  self,
  system,
  ...
}: {
  services.yabai = {
    enable = true;
    enableScriptingAddition = false;
    config = {
      layout = "bsp";
      window_placement             = "second_child";
      window_opacity               = "off";
      window_opacity_duration      = "0.0";
      window_border                = "on";
      window_border_placement      = "inset";
      window_border_width          = 2;
      window_border_radius         = 3;
      active_window_border_topmost = "on";
      window_topmost               = "on";
      window_shadow                = "float";
      active_window_border_color   = "0xff2bc559";
      normal_window_border_color   = "0xff505050";
      active_window_opacity        = "1.0";
      normal_window_opacity        = "1.0";
    };
    extraConfig = ''
      yabai -m rule --add app='System Settings' manage=off
    '';
  };
}
