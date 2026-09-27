{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
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
  config = mkIf cfg.enable (mkMerge [
    {
      users.groups.ambient = { };
      users.users.${config.system.primaryUser}.extraGroups = [ "ambient" ];

      systemd.tmpfiles.settings.ambient.${cfg.ambientDir}.d = {
        user = "root";
        group = "ambient";
        mode = "2775";
      };

      environment.systemPackages = [ ambientSet ];
    }

    # A fresh machine gets the default video while it is built: activation
    # (nixos-install, or the first switch) is the one time the network is
    # known to work, whereas the first boot may have none yet. An existing
    # video, or a deliberate `ambient-set --clear`, skips both paths. If the
    # download fails there (an offline install), activation only warns and
    # the service below retries once the machine is online.
    (mkIf (cfg.ambient.default != null) {
      system.activationScripts.ambientDefault = {
        deps = [
          "users"
          "groups"
        ];
        text = ''
          if [ ! -e ${cfg.ambientDir}/video ] && [ ! -e ${cfg.ambientDir}/cleared ]; then
            install -d -m 2775 -o root -g ambient ${cfg.ambientDir}
            echo "installing the default ambient video (one-time download)..."
            ${lib.getExe ambientSet} ${lib.escapeShellArg cfg.ambient.default} ||
              echo "warning: default ambient video not installed; ambient-default.service retries at boot" >&2
          fi
        '';
      };

      systemd.services.ambient-default = {
        description = "Install the default ambient video";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "systemd-tmpfiles-setup.service"
        ];
        unitConfig.ConditionPathExists = [
          "!${cfg.ambientDir}/video"
          "!${cfg.ambientDir}/cleared"
        ];
        serviceConfig = {
          Type = "oneshot";
          Group = "ambient";
          ExecStart = "${lib.getExe ambientSet} ${lib.escapeShellArg cfg.ambient.default}";
          Restart = "on-failure";
          RestartSec = "10min";
        };
      };
    })
  ]);
}
