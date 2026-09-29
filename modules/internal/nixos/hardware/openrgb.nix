{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.hrndz.hardware.openrgb;
  names = lib.attrNames cfg.lights;

  # Static colours default to the theme's accent, when there is one.
  accent = config.lib.stylix.colors.base0D or "44D62C";
  takesColor = mode: lib.elem "@color@" mode.args;

  # What the shell's lighting panel draws: each light and its modes.
  lightsJson = pkgs.writeText "rgb-lights.json" (
    builtins.toJSON (
      lib.mapAttrsToList (name: light: {
        inherit name;
        inherit (light) label;
        modes = map (mode: {
          inherit (mode) id label;
          color = takesColor mode;
        }) light.modes;
      }) cfg.lights
    )
  );

  modeArms = lib.concatStrings (
    lib.mapAttrsToList (
      name: light:
      lib.concatMapStrings (mode: ''
        ${name}:${mode.id})
          device=${lib.escapeShellArg light.device}
          colored=${lib.boolToString (takesColor mode)}
          args=(${
            lib.concatMapStringsSep " " (
              arg: if arg == "@color@" then ''"$color"'' else lib.escapeShellArg arg
            ) mode.args
          })
          ;;
      '') light.modes
    ) cfg.lights
  );

  rgbLighting = pkgs.writeShellApplication {
    name = "rgb-lighting";
    runtimeInputs = [ config.services.hardware.openrgb.package ];
    text = ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rgb-lighting"
      usage() {
        echo "usage: rgb-lighting list|status|restore|LIGHT MODE [RRGGBB]" >&2
        echo "lights: ${lib.concatStringsSep " " names}" >&2
        exit 2
      }

      case "''${1:-}" in
        list)
          cat ${lightsJson}
          exit
          ;;
        # "LIGHT MODE RRGGBB" per light: the last mode set here and the last
        # static colour, for the panel.
        status)
          for light in ${lib.concatStringsSep " " names}; do
            if [ -r "$state_dir/$light" ]; then echo "$light $(cat "$state_dir/$light")"; fi
          done
          exit
          ;;
        restore)
          for light in ${lib.concatStringsSep " " names}; do
            [ -r "$state_dir/$light" ] || continue
            read -r mode color <"$state_dir/$light" || true
            "$0" "$light" "$mode" ''${color:+"$color"} || true
          done
          exit
          ;;
      esac

      light="''${1:-}"
      mode="''${2:-}"
      color="''${3:-${accent}}"
      color="''${color#\#}"
      case "$light:$mode" in
      ${modeArms}
        *) usage ;;
      esac
      if $colored && ! [[ $color =~ ^[0-9A-Fa-f]{6}$ ]]; then usage; fi

      # Through the server, which the client finds on its default port:
      # standalone openrgb exits before sending the change, --noautoconnect
      # makes the client wait 5 s, and --client beside autoconnect joins twice.
      openrgb --nodetect -d "$device" "''${args[@]}" >/dev/null

      # Other modes keep the last static colour, so the panel still shows it.
      state="$state_dir/$light"
      if ! $colored && [ -r "$state" ]; then
        read -r _ color <"$state" || true
      fi
      mkdir -p "$state_dir"
      echo "$mode ''${color^^}" >"$state"
    '';
  };
in
{
  options.hrndz.hardware.openrgb = {
    enable = mkEnableOption "the OpenRGB server, with its effects plugin for audio-reactive lighting";

    lights = mkOption {
      default = { };
      description = ''
        Lights that `rgb-lighting` and the shell's lighting panel control, by
        short name.
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            label = mkOption {
              type = types.str;
              description = "Name shown in the lighting panel.";
            };
            device = mkOption {
              type = types.str;
              description = "Device name as `openrgb --list-devices` prints it.";
            };
            usbId = mkOption {
              type = types.strMatching "[0-9a-f]{4}:[0-9a-f]{4}";
              description = ''
                USB vendor:product id, lower case. The server only detects
                devices at start and keeps a dead handle when one reconnects,
                as a monitor does after standby, so it restarts when this is
                added.
              '';
            };
            modes = mkOption {
              description = "Modes in panel order.";
              type = types.listOf (
                types.submodule {
                  options = {
                    id = mkOption { type = types.str; };
                    label = mkOption { type = types.str; };
                    args = mkOption {
                      type = types.listOf types.str;
                      description = ''
                        openrgb arguments; `@color@` stands for the chosen
                        RRGGBB colour, which also gives the mode a colour
                        picker.
                      '';
                    };
                  };
                }
              );
            };
          };
        }
      );
    };
  };

  # OpenRGB drives devices over hidraw from userspace, so no kernel module.
  # The motherboard's SMBus (RAM and board LEDs) is left unprobed.
  config = mkIf cfg.enable {
    services.hardware.openrgb = {
      enable = true;
      # CEILING: local patch until OpenRGB spaces its reports to the Leviathan
      # V2 X upstream; without it most mode changes are silently dropped.
      package =
        (pkgs.openrgb.overrideAttrs (old: {
          patches = old.patches or [ ] ++ [ ./openrgb-leviathan-v2x-settle.patch ];
        })).withPlugins
          [ pkgs.openrgb-plugin-effects ];
      motherboard = null;
    };

    # A device with several HID interfaces restarts the server once per node;
    # the last restart sees them all.
    services.udev.extraRules = lib.concatMapStrings (
      light:
      let
        id = lib.splitString ":" light.usbId;
      in
      ''
        ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${lib.head id}", ATTRS{idProduct}=="${lib.last id}", RUN+="${config.systemd.package}/bin/systemctl --no-block try-restart openrgb.service"
      ''
    ) (lib.attrValues cfg.lights);

    environment.systemPackages = mkIf (cfg.lights != { }) [ rgbLighting ];

    # Lights keep OpenRGB's changes only until they lose power.
    systemd.user.services.rgb-lighting = mkIf (cfg.lights != { }) {
      description = "Restore the last lighting modes";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe rgbLighting} restore";
      };
    };

    hrndz.desktop.hyprland = mkIf (cfg.lights != { }) {
      barItems = [ "lighting" ];
      menuItems."setup.lighting" = {
        icon = "󰌵";
        label = "Lighting";
        aliases = [
          "rgb"
          "soundbar"
          "monitor"
        ];
        action = "@hrndzShell@ panel lighting";
      };
    };
  };
}
