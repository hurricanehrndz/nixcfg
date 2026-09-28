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
    mkMerge
    ;
  cfg = config.hrndz.hardware.razerLeviathanV2X;

  # When the kernel exposes both the per-channel and master volume, PipeWire
  # drives only the per-channel one and the master ('PCM Playback Volume',
  # index=1) keeps whatever it last held: ~29% from the factory, or wherever
  # macOS left it. When the kernel disables the per-channel control as sticky,
  # the master is PipeWire's slider and there is nothing to fix.
  leviathanVolume = pkgs.writeShellApplication {
    name = "leviathan-volume";
    runtimeInputs = [ pkgs.alsa-utils ];
    text = ''
      level="''${1:-100}"
      case "$level" in
        "" | *[!0-9]*)
          echo "usage: leviathan-volume [PERCENT]  (0-100, default 100)" >&2
          exit 2
          ;;
      esac
      if [ "$level" -gt 100 ]; then
        echo "leviathan-volume: $level is above 100" >&2
        exit 2
      fi

      card=""
      for usbid in /proc/asound/card*/usbid; do
        [ -r "$usbid" ] && [ "$(cat "$usbid")" = "1532:054a" ] || continue
        card="''${usbid#/proc/asound/card}"
        card="''${card%/usbid}"
      done
      if [ -z "$card" ]; then
        echo "leviathan-volume: Razer Leviathan V2 X not found" >&2
        exit 1
      fi

      control="name=PCM Playback Volume,index=1"
      if amixer -c "$card" cget "$control" >/dev/null 2>&1; then
        amixer -q -c "$card" cset "$control" "$level%"
        echo "Set the hidden master volume on card $card to $level%."
      else
        echo "Card $card has no separate master volume; the desktop slider already controls it."
      fi
    '';
  };

  # Breathing and static take their colours from the theme, when there is one.
  colors =
    config.lib.stylix.colors or {
      base0D = "44D62C";
      base0E = "00A0FF";
    };
  leviathanLighting = pkgs.writeShellApplication {
    name = "leviathan-lighting";
    runtimeInputs = [ config.services.hardware.openrgb.package ];
    text = ''
      case "''${1:-}" in
        breathing) args=(-m Breathing -c "${colors.base0D},${colors.base0E}") ;;
        spectrum) args=(-m "Spectrum Cycle") ;;
        wave) args=(-m Wave) ;;
        static) args=(-m Static -c "${colors.base0D}") ;;
        off) args=(-m Off) ;;
        *)
          echo "usage: leviathan-lighting breathing|spectrum|wave|static|off" >&2
          exit 2
          ;;
      esac
      # Through the server: standalone openrgb exits before sending the change.
      exec openrgb --client localhost:${toString config.services.hardware.openrgb.server.port} \
        --noautoconnect -d "Razer Leviathan V2 X" "''${args[@]}"
    '';
  };
  lightingModes = {
    breathing = "Breathing";
    spectrum = "Spectrum cycle";
    wave = "Wave";
    static = "Static";
    off = "Off";
  };
in
{
  options.hrndz.hardware.razerLeviathanV2X = {
    enable = mkEnableOption "Razer Leviathan V2 X (USB 1532:054a) soundbar support";

    rgb.enable = mkEnableOption "RGB control through OpenRGB, with its effects plugin for audio-reactive lighting";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ leviathanVolume ];
    }

    # OpenRGB drives the soundbar over hidraw from userspace, so no kernel module.
    # The motherboard's SMBus (RAM and board LEDs) is left unprobed.
    (mkIf cfg.rgb.enable {
      services.hardware.openrgb = {
        enable = true;
        package = pkgs.openrgb.withPlugins [ pkgs.openrgb-plugin-effects ];
        motherboard = null;
      };
      environment.systemPackages = [ leviathanLighting ];

      hrndz.desktop.hyprland.menuItems = {
        "setup.lighting" = {
          icon = "󰌵";
          label = "Soundbar lighting";
          aliases = [
            "lighting"
            "rgb"
            "soundbar"
          ];
        };
      }
      // lib.mapAttrs' (
        mode: label:
        lib.nameValuePair "setup.lighting.${mode}" {
          icon = "󰌵";
          inherit label;
          action = "${lib.getExe leviathanLighting} ${mode}";
        }
      ) lightingModes;
    })
  ]);
}
