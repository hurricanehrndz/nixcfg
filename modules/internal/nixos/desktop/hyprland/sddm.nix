{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz.desktop.hyprland;

  theme = pkgs.callPackage ../../../../../per-system/pkgs/by-name/hrndz-sddm-theme/package.nix {
    colors = config.lib.stylix.colors.withHashtag;
    font = lib.head config.fonts.fontconfig.defaultFonts.monospace;
    inherit (cfg) ambientDir;
  };
in
{
  # The login screen: SDDM with a theme laid out like the lock screen, playing
  # the ambient video (ambient.nix) from the wallpaper's frame. Its greeter
  # runs as user sddm, which reads the video from the ambient directory.
  config = mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "hrndz";
      # QtMultimedia with its FFmpeg backend, for the video.
      extraPackages = [ pkgs.kdePackages.qtmultimedia ];
      # The theme reads the still's time from a file next to the video.
      settings.General.GreeterEnvironment = "QML_XHR_ALLOW_FILE_READ=1";
    };

    # SDDM finds themes in the system profile.
    environment.systemPackages = [ theme ];
  };
}
