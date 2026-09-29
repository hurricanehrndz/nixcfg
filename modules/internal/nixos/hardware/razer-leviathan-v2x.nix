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

  # Static defaults to the theme's accent, when there is one.
  accent = config.lib.stylix.colors.base0D or "44D62C";
  leviathanLighting = pkgs.writeShellApplication {
    name = "leviathan-lighting";
    runtimeInputs = [ config.services.hardware.openrgb.package ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/leviathan-lighting"
      usage() {
        echo "usage: leviathan-lighting breathing|spectrum|wave|static [RRGGBB]|off|status|restore" >&2
        exit 2
      }

      mode="''${1:-}"
      color="''${2:-${accent}}"
      color="''${color#\#}"
      case "$mode" in
        # The last mode set here and the last static colour, for the panel.
        status)
          cat "$state" 2>/dev/null || true
          exit
          ;;
        restore)
          [ -r "$state" ] || exit 0
          read -r mode color <"$state"
          exec "$0" "$mode" ''${color:+"$color"}
          ;;
        # Random colours, as the soundbar breathes from the factory.
        breathing) args=(-m Breathing -c random) ;;
        spectrum) args=(-m "Spectrum Cycle") ;;
        wave) args=(-m Wave) ;;
        static)
          [[ $color =~ ^[0-9A-Fa-f]{6}$ ]] || usage
          args=(-m Static -c "$color")
          ;;
        off) args=(-m Off) ;;
        *) usage ;;
      esac

      # Through the server, which the client finds on its default port:
      # standalone openrgb exits before sending the change, --noautoconnect
      # makes the client wait 5 s, and --client beside autoconnect joins twice.
      openrgb --nodetect -d "Razer Leviathan V2 X" "''${args[@]}" >/dev/null

      # Other modes keep the last static colour, so the panel still shows it.
      if [ "$mode" != static ] && [ -r "$state" ]; then
        read -r _ color <"$state" || true
      fi
      mkdir -p "$(dirname "$state")"
      echo "$mode ''${color^^}" >"$state"
    '';
  };
in
{
  options.hrndz.hardware.razerLeviathanV2X = {
    enable = mkEnableOption "Razer Leviathan V2 X (USB 1532:054a) soundbar support";

    rgb.enable = mkEnableOption "lighting control through OpenRGB";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ leviathanVolume ];
    }

    (mkIf cfg.rgb.enable {
      hrndz.hardware.openrgb = {
        enable = true;
        devices = [ "1532:054a" ];
      };
      environment.systemPackages = [ leviathanLighting ];

      # The soundbar keeps OpenRGB's changes only until it loses power.
      systemd.user.services.leviathan-lighting = {
        description = "Restore the soundbar's last lighting mode";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe leviathanLighting} restore";
        };
      };

      hrndz.desktop.hyprland = {
        barItems = [ "lighting" ];
        menuItems."setup.lighting" = {
          icon = "󰌵";
          label = "Soundbar lighting";
          aliases = [
            "lighting"
            "rgb"
            "soundbar"
          ];
          action = "@hrndzShell@ panel lighting";
        };
      };
    })
  ]);
}
