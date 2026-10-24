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
    inherit (cfg.ambient) playbackRate;
    image = cfg.lockImage;
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
      # nixpkgs' weston.ini plus require-outputs: the monitor can still be
      # waking when the greeter starts, and by default Weston exits without an
      # output and leaves a black screen. Keep the rest in sync with nixpkgs.
      wayland.compositorCommand =
        let
          xkb = config.services.xserver.xkb;
          westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
            core.require-outputs = "none";
            libinput = {
              enable-tap = config.services.libinput.mouse.tapping;
              left-handed = config.services.libinput.mouse.leftHanded;
            };
            keyboard = {
              keymap_model = xkb.model;
              keymap_layout = xkb.layout;
              keymap_variant = xkb.variant;
              keymap_options = xkb.options;
            };
          };
        in
        "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
    };

    # SDDM finds themes in the system profile.
    environment.systemPackages = [ theme ];
  };
}
