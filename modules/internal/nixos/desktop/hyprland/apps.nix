{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) genAttrs mkDefault mkIf;

  defaults = desktop: types: genAttrs types (_: mkDefault desktop);
  omasnap = pkgs.callPackage ../../../../../per-system/pkgs/by-name/omasnap/package.nix { };
in
{
  # The desktop's everyday apps, after Omarchy's base set: capture, media,
  # documents and file sharing.
  config = mkIf config.hrndz.desktop.hyprland.enable {
    # hrndz-shell screenrecord; the setcap helper records without a prompt.
    programs.gpu-screen-recorder.enable = true;

    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    programs.localsend.enable = true;

    environment.systemPackages = with pkgs; [
      celluloid
      fastfetch
      imv
      mpv
      omasnap
      papers
      pdfarranger
      xournalpp
    ];

    xdg.mime.defaultApplications =
      defaults "io.github.celluloid_player.Celluloid.desktop" [
        "video/mp4"
        "video/mpeg"
        "video/ogg"
        "video/quicktime"
        "video/webm"
        "video/x-matroska"
        "video/x-msvideo"
      ]
      // defaults "imv.desktop" [
        "image/bmp"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
      ]
      // defaults "org.gnome.Papers.desktop" [ "application/pdf" ];
  };
}
