{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  colors = config.lib.stylix.colors.withHashtag;

  # Hyprland's drop, without the wordmark (the left third of its header
  # logo), recoloured from the scheme's cyan down to its blue, the way
  # Hyprland's own gradient runs.
  hyprlandDrop =
    pkgs.runCommand "hyprland-drop.png"
      {
        nativeBuildInputs = [
          pkgs.imagemagick
          pkgs.librsvg
        ];
      }
      ''
        rsvg-convert -h 600 ${config.programs.hyprland.package.src}/assets/header.svg -o header.png
        magick header.png -crop 34%x100%+0+0 +repage -trim +repage -resize x200 \
          -channel RGB \
          -sparse-color Barycentric '0,0 ${colors.base0C} 0,%[fx:h-1] ${colors.base0D}' \
          +channel $out
      '';
in
{
  # The boot splash: Stylix's Plymouth theme (the scheme's background, the
  # LUKS prompt in its text colour) with the Hyprland drop, held still since
  # it has no rotational symmetry to spin.
  config = mkIf config.hrndz.desktop.hyprland.enable {
    boot.plymouth.enable = true;
    stylix.targets.plymouth = {
      enable = true;
      logo = hyprlandDrop;
      logoAnimated = false;
    };

    # Keep kernel and initrd messages off the splash (plymouth adds "splash").
    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;
  };
}
