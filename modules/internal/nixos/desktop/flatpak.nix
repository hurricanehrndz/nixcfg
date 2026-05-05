{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.hrndz.desktop.flatpak;

  ensureRemotes = concatStringsSep "\n" (
    mapAttrsToList (
      name: url:
      "flatpak remote-add --system --if-not-exists ${escapeShellArg name} ${escapeShellArg url}"
    ) cfg.remotes
  );

  installPackages = concatStringsSep "\n" (
    map (
      appId:
      "flatpak install --system --assumeyes --noninteractive --or-update ${escapeShellArg cfg.defaultRemote} ${escapeShellArg appId}"
    ) cfg.packages
  );
in
{
  options.hrndz.desktop.flatpak = {
    enable = mkEnableOption "Flatpak desktop application support";

    defaultRemote = mkOption {
      type = types.str;
      default = "flathub";
      description = "Default Flatpak remote used for declarative package installs.";
    };

    remotes = mkOption {
      type = types.attrsOf types.str;
      default = {
        flathub = "https://flathub.org/repo/flathub.flatpakrepo";
      };
      description = "Flatpak remotes to configure system-wide.";
    };

    packages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "com.discordapp.Discord" ];
      description = "Flatpak application IDs to install from the default remote.";
    };

    update = {
      enable = mkEnableOption "scheduled Flatpak updates" // {
        default = true;
      };

      onCalendar = mkOption {
        type = types.str;
        default = "weekly";
        description = "systemd calendar expression for Flatpak updates.";
      };
    };
  };

  config = mkMerge [
    (mkIf config.hrndz.desktop.hyprland.enable {
      hrndz.desktop.flatpak.enable = mkDefault true;
    })

    (mkIf cfg.enable {
      services.flatpak.enable = true;

      systemd.services.flatpak-apply = {
        description = "Apply declarative Flatpak configuration";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ pkgs.flatpak ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          ${ensureRemotes}
          ${installPackages}
        '';
      };
    })

    (mkIf (cfg.enable && cfg.update.enable) {
      systemd.services.flatpak-update = {
        description = "Update Flatpak applications";
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "flatpak-apply.service"
        ];
        path = [ pkgs.flatpak ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          ${ensureRemotes}
          flatpak update --system --assumeyes --noninteractive
        '';
      };

      systemd.timers.flatpak-update = {
        description = "Update Flatpak applications weekly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.update.onCalendar;
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    })
  ];
}
