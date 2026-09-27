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

  # CEILING: openrazer PR #2903 (Leviathan V2 X support) pinned by commit until it
  # ships in a release that reaches nixpkgs; drop the overrides below then.
  openrazerSrc = pkgs.fetchFromGitHub {
    owner = "openrazer";
    repo = "openrazer";
    rev = "4cf64b78dd99634f63ca3ed7675452799662eea8";
    hash = "sha256-2cRazHLy17RRb04ZvIVXOLKQJYIAP2GyZBtwOwIKR9w=";
  };

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
in
{
  options.hrndz.hardware.razerLeviathanV2X = {
    enable = mkEnableOption "Razer Leviathan V2 X (USB 1532:054a) soundbar support";

    rgb.enable = mkEnableOption "RGB control through a patched OpenRazer driver and daemon";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ leviathanVolume ];
    }

    (mkIf cfg.rgb.enable {
      hardware.openrazer = {
        enable = true;
        users = [ config.system.primaryUser ];
        packages = {
          kernel = config.boot.kernelPackages.openrazer.overrideAttrs { src = openrazerSrc; };
          daemon = pkgs.python3Packages.openrazer-daemon.overridePythonAttrs { src = openrazerSrc; };
        };
      };
    })
  ]);
}
