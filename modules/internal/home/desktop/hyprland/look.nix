{
  config,
  lib,
  ...
}:
let
  curve = name: points: {
    _args = [
      name
      {
        type = "bezier";
        inherit points;
      }
    ];
  };

  animation = leaf: speed: bezier: {
    inherit leaf speed bezier;
    enabled = true;
  };
  withStyle = style: attrs: attrs // { inherit style; };
  disabled = leaf: {
    inherit leaf;
    enabled = false;
  };
in
{
  # Colours come from Stylix's hyprland target.
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      # https://wiki.hypr.land/Configuring/Basics/Variables/
      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 0;
          shadow.enabled = false;
          blur.enabled = false;
        };

        group.groupbar = {
          font_size = 12;
          font_family = "monospace";
          font_weight_active = "ultraheavy";
          font_weight_inactive = "normal";
          indicator_height = 1;
          indicator_gap = 5;
          height = 22;
          gaps_in = 5;
          gaps_out = 0;
          gradients = true;
          gradient_rounding = 0;
          gradient_round_only_edges = false;
        };

        animations.enabled = true;

        dwindle = {
          preserve_split = true;
          force_split = 2;
        };

        scrolling.column_width = 0.49;

        master.new_status = "master";

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_scale_notification = true;
          focus_on_activate = true;
          anr_missed_pings = 3;
          on_focus_under_fullscreen = 1;
          initial_workspace_tracking = 0;
          # Lets a restarted shell re-acquire the session lock after its lock
          # client died.
          allow_session_lock_restore = true;
        };

        cursor = {
          hide_on_key_press = true;
          warp_on_change_workspace = 1;
        };

        binds.hide_special_on_workspace_change = true;
      };

      # https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
      curve = [
        (curve "easeOutQuint" [
          [
            0.23
            1
          ]
          [
            0.32
            1
          ]
        ])
        (curve "easeInOutCubic" [
          [
            0.65
            0.05
          ]
          [
            0.36
            1
          ]
        ])
        (curve "linear" [
          [
            0
            0
          ]
          [
            1
            1
          ]
        ])
        (curve "almostLinear" [
          [
            0.5
            0.5
          ]
          [
            0.75
            1.0
          ]
        ])
        (curve "quick" [
          [
            0.15
            0
          ]
          [
            0.1
            1
          ]
        ])
      ];

      animation = [
        (animation "global" 10 "default")
        (animation "border" 5.39 "easeOutQuint")
        (animation "windows" 3.79 "easeOutQuint")
        (withStyle "popin 87%" (animation "windowsIn" 4.1 "easeOutQuint"))
        (withStyle "popin 87%" (animation "windowsOut" 1.49 "linear"))
        (animation "fadeIn" 1.73 "almostLinear")
        (animation "fadeOut" 1.46 "almostLinear")
        (animation "fade" 3.03 "quick")
        (disabled "fadeSwitch")
        (animation "layers" 3.81 "easeOutQuint")
        (withStyle "fade" (animation "layersIn" 4 "easeOutQuint"))
        (withStyle "fade" (animation "layersOut" 1.5 "linear"))
        (animation "fadeLayersIn" 1.79 "almostLinear")
        (animation "fadeLayersOut" 1.39 "almostLinear")
        (disabled "workspaces")
        (withStyle "slidevert" (animation "specialWorkspace" 3 "easeOutQuint"))
      ];
    };
  };
}
