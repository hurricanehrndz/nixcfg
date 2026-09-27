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
    mkOption
    types
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
in
{
  options.hrndz.hardware.razerLeviathanV2X = {
    enable = mkEnableOption "Razer Leviathan V2 X (USB 1532:054a) soundbar support";

    internalVolume = mkOption {
      type = types.ints.between 0 100;
      default = 100;
      description = ''
        Level, in percent, for the soundbar's hidden master volume
        ('PCM Playback Volume',index=1; 100% is -0.06 dB). Some units boot it at
        ~29%, which only Razer Synapse raises; PipeWire drives the per-channel
        control, so unity here leaves the desktop slider in charge.
      '';
    };

    rgb.enable = mkEnableOption "RGB control through a patched OpenRazer driver and daemon";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="sound", KERNEL=="controlC*", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="054a", RUN+="${pkgs.alsa-utils}/bin/amixer -q -c %n cset 'name=PCM Playback Volume,index=1' ${toString cfg.internalVolume}%"
      '';
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
