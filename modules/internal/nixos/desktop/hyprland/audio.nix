{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.hrndz.desktop.hyprland.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    services.pulseaudio.enable = false;
  };
}
