{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  # EasyEffects applies the EQ in PipeWire, so it works for any output device.
  # Presets and per-device autoload are saved from its UI and stay writable.
  config = lib.mkIf ((osConfig.hrndz.desktop.hyprland.enable or false) && isLinux) {
    services.easyeffects.enable = true;
  };
}
