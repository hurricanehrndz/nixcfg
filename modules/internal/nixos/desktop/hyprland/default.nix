{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.hrndz.desktop.hyprland;
  stablePkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.hrndz.desktop.hyprland = {
    enable = mkEnableOption "the personal Hyprland desktop";

    # One build of the shell for the fonts, desktop-vnc and Home Manager. Its
    # passthru.omasnap is the omasnap build apps.nix installs.
    shellPackage = mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      default = pkgs.callPackage ../../../../../per-system/pkgs/by-name/hrndz-shell/package.nix {
        hyprland = config.programs.hyprland.package;
        # Quickshell on the 26.05 release's Qt 6.11: on Qt 6.12 the lock
        # screen's video stutters and freezes. Only Qt comes from 26.05; a
        # whole-26.05 build has an older glibc than the system's GPU driver
        # and gets no EGL. This costs a second Qt in the closure; drop these
        # lines once a 6.12 point release plays the lock preview smoothly.
        inherit (stablePkgs) qt6;
        quickshell = pkgs.quickshell.override { inherit (stablePkgs) qt6; };
        omasnap = pkgs.callPackage ../../../../../per-system/pkgs/by-name/omasnap/package.nix {
          inherit inputs;
        };
        inherit (cfg.ambient) playbackRate;
        inherit (cfg) lockImage;
        lockBlankSeconds = cfg.idle.lockBlank;
        extraMenuItems = cfg.menuItems;
      };
    };

    barItems = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "lighting" ];
      description = ''
        Host-specific bar panels, by name, placed in the right section before
        the audio panel.
      '';
    };

    menuItems = mkOption {
      type = types.attrsOf (types.attrsOf types.anything);
      default = { };
      description = ''
        Host-specific rows added to the shell menu, keyed by menu id, in the
        same shape as menu.jsonc (for example `"setup.foo".action`).
      '';
    };

    lockImage = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Image behind the lock and login screens. Null plays the ambient
        video on both instead.
      '';
    };

    # Where ambient-set keeps the video and still the screensaver, lock screen
    # and login screen share (ambient.nix). The shell reads it from there.
    ambientDir = mkOption {
      type = types.str;
      readOnly = true;
      internal = true;
      default = cfg.shellPackage.ambientDir;
    };

    ambient.default = mkOption {
      type = types.nullOr types.str;
      default = "https://www.youtube.com/watch?v=qKJUWWTwPO0";
      description = ''
        Video (a URL yt-dlp can fetch, or a local path) installed with
        ambient-set when the machine has none, so a fresh install boots into
        the usual wallpaper and screensaver. Not re-applied after
        `ambient-set --clear`. Null for none.
      '';
    };

    ambient.playbackRate = mkOption {
      type = types.numbers.between 0.1 4.0;
      default = 0.5;
      description = ''
        Playback speed of the ambient video on the screensaver, lock screen
        and login screen; 1.0 is the video's own speed.
      '';
    };

    # Seconds of inactivity; hypridle (Home Manager) acts on them.
    idle = {
      screensaver = mkOption {
        type = types.nullOr types.ints.positive;
        default = 240;
        description = "When the ambient video screensaver starts; null for none.";
      };
      lock = mkOption {
        type = types.ints.positive;
        default = 300;
        description = "When the session locks.";
      };
      displaysOff = mkOption {
        type = types.ints.positive;
        default = 330;
        description = "When the displays turn off.";
      };
      lockBlank = mkOption {
        type = types.ints.positive;
        default = 60;
        description = "How long the lock screen stays lit after the last input.";
      };
    };

    weather.location = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name the weather panel shows.";
            };
            latitude = mkOption { type = types.float; };
            longitude = mkOption { type = types.float; };
          };
        }
      );
      default = null;
      description = ''
        Where the bar's weather widget reports for. Null locates the machine
        from nearby Wi-Fi through GeoClue and BeaconDB, falling back to
        wttr.in's public-IP lookup. Set it for a fixed place, e.g. behind a
        VPN exit node.
      '';
    };
  };
}
