{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz.desktop.hyprland;

  ambientSet = pkgs.writeShellApplication {
    name = "ambient-set";
    runtimeInputs = [
      cfg.shellPackage
      pkgs.coreutils
      pkgs.ffmpeg-headless
      pkgs.findutils
      pkgs.gawk
      pkgs.yt-dlp
    ];
    runtimeEnv.AMBIENT_DIR = cfg.ambientDir;
    text = builtins.readFile ./ambient-set.sh;
  };
in
{
  # The ambient video (and its still) that the wallpaper, screensaver, lock
  # screen and login screen share. It changes at runtime, without a rebuild,
  # so it lives outside the store: in a directory the greeter (user sddm, no
  # access to $HOME) can read. The primary user installs videos with
  # ambient-set through membership of the `ambient` group, which can write
  # there and nowhere else: no sudo rule or polkit action is involved. The
  # setgid bit keeps new files in the group; ambient-set makes them
  # world-readable.
  config = mkIf cfg.enable {
    users.groups.ambient = { };
    users.users.${config.system.primaryUser}.extraGroups = [ "ambient" ];

    systemd.tmpfiles.settings.ambient.${cfg.ambientDir}.d = {
      user = "root";
      group = "ambient";
      mode = "2775";
    };

    environment.systemPackages = [ ambientSet ];
  };
}
