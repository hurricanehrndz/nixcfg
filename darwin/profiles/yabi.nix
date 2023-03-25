{
  config,
  lib,
  pkgs,
  self,
  system,
  ...
}: let
  mkArgString = lib.generators.toKeyValue {
    mkKeyValue = key: value: let
      value' =
        if lib.isBool value
        then
          (
            if value
            then "on"
            else "off"
          )
        else builtins.toString value;
    in "${key}='${value'}' \\";
  };

  mkRule = {app, ...} @ args: let
    args' =
      lib.filterAttrs
      (n: _: ! builtins.elem n ["app"])
      args;
  in ''
    yabai -m rule --add app='${app}' ${mkArgString args'}
  '';

  mkRules = lib.strings.concatMapStringsSep "\n" mkRule;
in {
  services.yabai = {
    enable = true;
    enableScriptingAddition = false;
    config = {
      layout = "bsp";
      window_placement = "second_child";
      window_opacity = "off";
      window_opacity_duration = "0.0";
      window_border = "on";
      window_border_placement = "inset";
      window_border_width = 2;
      window_border_radius = 3;
      active_window_border_topmost = "on";
      window_topmost = "on";
      window_shadow = "float";
      active_window_border_color = "0xff2bc559";
      normal_window_border_color = "0xff505050";
      active_window_opacity = "1.0";
      normal_window_opacity = "1.0";
    };
    extraConfig = let
      commonRules = {
        manage = false;
        sticky = false;
      };

      rules = mkRules [
        # Stop system settings from taking up a space
        (commonRules // {app = "System Settings";})

        # Prevent tiny file copy dialogs from claiming a space partition.
        (commonRules
          // {
            app = "^Finder$";
            title = "Copy";
          })
      ];
    in ''
      ###: NOTEBOOK WORKSPACES {{{
        #: 'home' :: personal browser etc.
        yabai -m space 1 --label 'home'
        #: 'work' :: work browser + slack
        yabai -m space 2 --label 'work'
        #: 'code' :: wezterm, vscode
        yabai -m space 3 --label 'code'
        #: 'media' :: audio/video player
        yabai -m space 4 --label 'media'
        # yabai -m signal --add label=app_warp_east event=application_launched action="~/Documents/autosplit.sh"
        # yabai -m signal --add label=win__warp_east event=window_created action="~/Documents/autowindow.sh"
        yabai -m signal --add event=window_created action="~/Documents/yabai-insert.sh"
        yabai -m signal --add event=window_destroyed action="~/Documents/yabai-insert.sh"
        yabai -m signal --add event=window_deminimized action="~/Documents/yabai-insert.sh"

      ### }}}
      ${rules}
    '';
  };
}
