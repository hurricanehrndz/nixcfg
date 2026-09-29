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
in
{
  options.hrndz.hardware.openrgb = {
    enable = mkEnableOption "the OpenRGB server, with its effects plugin for audio-reactive lighting";

    devices = mkOption {
      type = types.listOf (types.strMatching "[0-9a-f]{4}:[0-9a-f]{4}");
      default = [ ];
      example = [ "043e:9a8a" ];
      description = ''
        USB ids (vendor:product, lower case) of the RGB devices in use. The
        server only detects devices at start and keeps a dead handle when one
        reconnects, as a monitor does after standby, so it restarts when any of
        these is added.
      '';
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
      id:
      let
        vendor = lib.head (lib.splitString ":" id);
        product = lib.last (lib.splitString ":" id);
      in
      ''
        ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${vendor}", ATTRS{idProduct}=="${product}", RUN+="${config.systemd.package}/bin/systemctl --no-block try-restart openrgb.service"
      ''
    ) cfg.devices;
  };
}
