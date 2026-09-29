{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  appimage = pkgs.writeShellApplication {
    name = "appimage";
    runtimeInputs = [
      config.programs.appimage.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
    ];
    text = builtins.readFile ./appimage.sh;
  };
in
{
  config = mkIf config.hrndz.desktop.hyprland.enable {
    # Prebuilt binaries (downloaded language servers, npm/pip natives) and
    # scripts with FHS shebangs just work; AppImages run directly.
    # The library list is nixarchy's; it merges with nixpkgs' base set.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        libGL
        wayland
        libxkbcommon
        libx11
        libxcb
        libxcursor
        libxrandr
        libxi
        libxext
        fontconfig
        freetype
        glib
        nss
        nspr
        alsa-lib
        ffmpeg
        zlib
        openssl
        libxml2
      ];
    };
    services.envfs.enable = true;
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
    environment.systemPackages = [ appimage ];
  };
}
