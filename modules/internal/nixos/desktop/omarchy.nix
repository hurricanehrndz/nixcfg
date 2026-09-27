{
  config,
  inputs,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.hrndz.desktop.omarchy;
  omarchyPath = "${cfg.package}/share/omarchy";
  system = pkgs.stdenv.hostPlatform.system;

  # The Hyprland nixarchy tests Omarchy against (>= 0.55, for the Lua config API).
  hyprlandPkgs = inputs.nixarchy.inputs.hyprland.packages.${system};

  # Runs Hyprland against Omarchy's own hyprland.lua from the store. That file
  # then loads the user overrides in ~/.config/hypr/*.lua.
  sessionLauncher = pkgs.writeShellScript "omarchy-session" ''
    export OMARCHY_PATH=${cfg.package}/share/omarchy
    exec ${pkgs.uwsm}/bin/uwsm start -N Omarchy -D Hyprland -- \
      ${config.programs.hyprland.package}/bin/start-hyprland -- \
      --config ${cfg.package}/share/omarchy/config/hypr/hyprland.lua
  '';

  sessionPackage =
    (pkgs.writeTextFile {
      name = "omarchy-wayland-session";
      destination = "/share/wayland-sessions/omarchy.desktop";
      text = ''
        [Desktop Entry]
        Name=Omarchy
        Comment=Omarchy on NixOS, through Hyprland
        Exec=${sessionLauncher}
        Type=Application
        DesktopNames=Hyprland
      '';
    }).overrideAttrs
      (_: {
        passthru.providedSessions = [ "omarchy" ];
      });

  # On-demand VNC into the Omarchy desktop, mostly for agents and rare checks.
  # Attaches to a running session, or starts a seatless one (libseat noop:
  # the GPU is opened with the user's video-group access, so no login or
  # monitor is needed). Adds a virtual output only when no display is plugged
  # in. VNC listens on localhost only; reach it through an SSH tunnel.
  desktopVnc = pkgs.writeShellApplication {
    name = "desktop-vnc";
    runtimeInputs = [
      config.programs.hyprland.package
      cfg.package
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.jq
      pkgs.systemd
      pkgs.wayvnc
    ];
    text = ''
      bind=127.0.0.1
      port=5900
      output_name=VNC-1
      session_unit=omarchy-headless
      vnc_unit=desktop-vnc
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export OMARCHY_PATH="${omarchyPath}"
      state="$XDG_RUNTIME_DIR/desktop-vnc"

      usage() {
        echo "usage: desktop-vnc start|stop|status"
        echo
        echo "  start   attach to (or start) the Omarchy session and serve it over VNC"
        echo "          on $bind:$port. Connect with: ssh -L $port:$bind:$port $(uname -n)"
        echo "  stop    stop VNC; also stops the session and virtual output if start made them"
        echo "  status  show session, output and VNC state"
      }

      display_connected() {
        grep -qx connected /sys/class/drm/card*-*/status 2>/dev/null
      }

      # Prints "<instance signature> <wayland socket>" of the running Hyprland.
      instance() {
        # Without a running Hyprland this prints non-JSON; treat that as none.
        hyprctl instances -j 2>/dev/null | jq -r 'first(.[] | "\(.instance) \(.wl_socket)") // empty' 2>/dev/null || true
      }

      unit_active() {
        systemctl --user is-active --quiet "$1"
      }

      start_session() {
        echo "No Omarchy session running; starting a headless one."
        systemctl --user reset-failed "$session_unit" 2>/dev/null || true
        systemd-run --user --quiet --unit="$session_unit" \
          -E OMARCHY_PATH="${omarchyPath}" \
          -E LIBSEAT_BACKEND=noop \
          -E XDG_SESSION_TYPE=wayland \
          -E XDG_CURRENT_DESKTOP=Hyprland \
          -E XDG_SESSION_DESKTOP=Hyprland \
          start-hyprland -- --config "${omarchyPath}/config/hypr/hyprland.lua"
        for _ in $(seq 1 30); do
          [ -n "$(instance)" ] && return 0
          sleep 0.5
        done
        echo "desktop-vnc: Hyprland did not come up; see: journalctl --user -u $session_unit" >&2
        exit 1
      }

      cmd_start() {
        mkdir -p "$state"
        if unit_active "$vnc_unit"; then
          echo "VNC is already running on $bind:$port."
          return 0
        fi

        if [ -z "$(instance)" ]; then
          start_session
          touch "$state/session"
          # A monitor is plugged in, so this session is visible on it: lock
          # before anything is served. Unlock over VNC with your password.
          if display_connected; then
            for _ in $(seq 1 40); do
              omarchy-shell lock lock >/dev/null 2>&1 && break
              sleep 0.5
            done
          fi
        fi

        read -r sig socket < <(instance)
        export HYPRLAND_INSTANCE_SIGNATURE="$sig"

        output=""
        if [ "$(hyprctl monitors -j | jq length)" -eq 0 ] || ! display_connected; then
          if ! hyprctl monitors -j | jq -e --arg n "$output_name" 'any(.[]; .name == $n)' >/dev/null; then
            hyprctl output create headless "$output_name" >/dev/null
            touch "$state/output"
          fi
          output="$output_name"
        fi

        systemctl --user reset-failed "$vnc_unit" 2>/dev/null || true
        systemd-run --user --quiet --unit="$vnc_unit" \
          -E WAYLAND_DISPLAY="$socket" \
          wayvnc ''${output:+-o "$output"} "$bind" "$port"
        sleep 1
        if ! unit_active "$vnc_unit"; then
          echo "desktop-vnc: wayvnc exited; see: journalctl --user -u $vnc_unit" >&2
          exit 1
        fi
        echo "VNC on $bind:$port''${output:+ (virtual output $output)}."
        echo "Connect with: ssh -L $port:$bind:$port $(uname -n), then a VNC client on localhost:$port"
      }

      cmd_stop() {
        systemctl --user stop "$vnc_unit" 2>/dev/null || true
        if [ -e "$state/output" ]; then
          read -r sig _ < <(instance) || true
          if [ -n "''${sig:-}" ]; then
            HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl output remove "$output_name" >/dev/null || true
          fi
          rm -f "$state/output"
        fi
        if [ -e "$state/session" ]; then
          systemctl --user stop "$session_unit" 2>/dev/null || true
          rm -f "$state/session"
          echo "Stopped VNC and the headless session."
        else
          echo "Stopped VNC."
        fi
      }

      cmd_status() {
        if [ -n "$(instance)" ]; then
          if [ -e "$state/session" ]; then
            echo "session: running (headless, started by desktop-vnc)"
          else
            echo "session: running (console login)"
          fi
        else
          echo "session: none"
        fi
        if display_connected; then echo "display: connected"; else echo "display: none"; fi
        if [ -e "$state/output" ]; then echo "output:  $output_name (virtual)"; fi
        if unit_active "$vnc_unit"; then echo "vnc:     listening on $bind:$port"; else echo "vnc:     stopped"; fi
      }

      case "''${1:-}" in
        start) cmd_start ;;
        stop) cmd_stop ;;
        status) cmd_status ;;
        -h | --help | help) usage ;;
        *) usage >&2; exit 2 ;;
      esac
    '';
  };

  # Chromium/Brave toolbar colour from the Omarchy theme, as a managed policy.
  # Omarchy's own hook (omarchy-theme-set-browser) needs root-owned policy dirs
  # written through sudo at /usr/bin paths, so it can't run here; this is the
  # same policy, computed the way omarchy-theme-set does, from the theme's
  # colors.toml background. Omarchy web apps run in Chromium.
  # CEILING: follows hrndz.theme.omarchy.theme at rebuild, not Style-menu
  # switches. Upgrade path: a root oneshot that rewrites the file from
  # ~/.local/state/omarchy/current/theme when the theme changes.
  themeColors = "${inputs.nixarchy.inputs.omarchy}/themes/${config.hrndz.theme.omarchy.theme}/colors.toml";
  browserThemePolicy.text = builtins.toJSON {
    BrowserThemeColor =
      if builtins.pathExists themeColors then
        (builtins.fromTOML (builtins.readFile themeColors)).background
      else
        "#1c2027";
    BrowserColorScheme = "device";
  };

  # /etc files upstream installs on Arch that the Omarchy tree expects.
  installedEtc = lib.attrNames (
    lib.filterAttrs (_: row: row.class == "installed") (
      import "${inputs.nixarchy}/data/etc-overlay.nix"
    )
  );
in
{
  options.hrndz.desktop.omarchy = {
    enable = mkEnableOption "the Omarchy desktop (Hyprland + Quickshell)";

    package = mkOption {
      type = types.package;
      default = inputs.nixarchy.packages.${system}.omarchy;
      defaultText = lib.literalExpression "inputs.nixarchy.packages.\${system}.omarchy";
      description = "The vendored Omarchy tree, patched for NixOS.";
    };

    flake = mkOption {
      type = types.str;
      default = "/home/${config.system.primaryUser}/src/me/nixcfg";
      description = "Flake Omarchy's Update menu rebuilds from (via nh).";
    };
  };

  config = mkIf cfg.enable {
    ##: Hyprland, pinned to what nixarchy tests Omarchy against
    programs.hyprland = {
      enable = true;
      package = hyprlandPkgs.hyprland;
      portalPackage = hyprlandPkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      withUWSM = true;
    };

    # nixarchy.cachix is not listed: nixarchy follows our nixpkgs, so none of
    # its outputs can match. Hyprland keeps its own nixpkgs and still hits.
    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIITemDosxrE9/Kb+PfYvE="
      ];
    };

    ##: Login screen - SDDM with Omarchy's theme, offering the Omarchy session
    # The theme ships in the package at share/sddm/themes/omarchy, linked into
    # the system profile through environment.systemPackages.
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        theme = "omarchy";
      };
      sessionPackages = [ sessionPackage ];
    };

    ##: Boot splash - Plymouth with Omarchy's theme
    boot.plymouth = {
      enable = true;
      themePackages = [ cfg.package ];
      theme = "omarchy";
    };
    # Keep kernel and initrd messages off the splash (plymouth adds "splash").
    boot.kernelParams = [
      "quiet"
      # USB devices stay awake (keyboards, the soundbar). A kernel parameter,
      # not modprobe options: usbcore is built in (CONFIG_USB=y), so nixarchy's
      # extraModprobeConfig form never reaches it.
      "usbcore.autosuspend=-1"
    ];
    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;

    ##: Settings adopted from nixarchy's module (which is not imported)
    # Locks the screen before suspend; InhibitDelayMaxSec below gives it time.
    systemd.user.services.omarchy-sleep-lock = {
      description = "Lock Omarchy before suspend";
      after = [
        "dbus.socket"
        "wayland-session-waitenv.service"
      ];
      requires = [ "dbus.socket" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      path = [ "/run/current-system/sw" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      # The monitor finds its companion omarchy-system-sleep-lock via $OMARCHY_PATH.
      environment.OMARCHY_PATH = "${cfg.package}/share/omarchy";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/omarchy-system-sleep-monitor";
        Restart = "always";
        RestartSec = 2;
      };
    };

    # Omarchy's first run hardcodes a dark GNOME scheme (first-run/gnome-theme.sh),
    # and the first theme is applied headless, which skips the hook that would
    # match it. Re-apply the current theme's light/dark at each login, once
    # first-run is done; GTK apps and Zen follow it.
    systemd.user.services.omarchy-theme-gnome-sync = {
      description = "Match GNOME light/dark to the current Omarchy theme";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      path = [ "/run/current-system/sw" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      environment.OMARCHY_PATH = "${cfg.package}/share/omarchy";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "150s";
      };
      script = ''
        for _ in $(seq 120); do
          omarchy-done check first-run-user && break
          sleep 1
        done
        omarchy-theme-set-gnome
      '';
    };

    # External-monitor brightness over DDC/CI (omarchy-brightness-display-ddc).
    hardware.i2c.enable = true;

    # Prebuilt binaries (downloaded language servers, npm/pip natives) and
    # scripts with FHS shebangs just work; AppImages run directly.
    programs.nix-ld.enable = true;
    services.envfs.enable = true;
    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    # Proton/Wine and file watchers want more than the default 1024 soft limit.
    # A 15s stop timeout (nixarchy uses 5s) still lets VMs and containers shut
    # down cleanly while avoiding 90s hangs.
    systemd.settings.Manager = {
      DefaultLimitNOFILE = "65536:524288";
      DefaultTimeoutStopSec = "15s";
    };
    # systemd.user.settings is unstable-only; 26.05 still has extraConfig.
    systemd.user.${if options.systemd.user ? settings then "settings" else "extraConfig"} =
      if options.systemd.user ? settings then
        { Manager.DefaultLimitNOFILE = "65536:524288"; }
      else
        "DefaultLimitNOFILE=65536:524288";
    systemd.services."user@".serviceConfig.TimeoutStopSec = "15s";

    # Printing with network discovery; cups-browsed stays off, as in nixarchy.
    services.printing = {
      enable = true;
      browsed.enable = false;
    };
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.logind.settings.Login = {
      # Omarchy binds the power button to its power menu; logind's default
      # "poweroff" would shut the machine down before the menu could open.
      HandlePowerKey = "ignore";
      # omarchy-sleep-lock holds a delay inhibitor while the shell secures the
      # screen; logind's 5s default can suspend before the lock is up.
      InhibitDelayMaxSec = 15;
    };

    # Keep the user manager running without a login, so a session started by
    # desktop-vnc over SSH survives the SSH connection closing.
    # i2c: DDC/CI brightness for external monitors (hardware.i2c below).
    users.users.${config.system.primaryUser} = {
      linger = true;
      extraGroups = [ "i2c" ];
    };

    ##: Omarchy tree and what its scripts shell out to
    environment.sessionVariables = {
      OMARCHY_PATH = "${cfg.package}/share/omarchy";
      OMARCHY_SCREENSHOT_EDITOR = mkDefault "satty-edit";
      # Read by `omarchy update`, which rebuilds through nh.
      NIXARCHY_FLAKE = cfg.flake;
      NH_FLAKE = cfg.flake;
      XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = [
      cfg.package
      sessionPackage
      desktopVnc
    ]
    # The session's Hyprland comes from programs.hyprland, not the tree's deps.
    # Foot is dropped: Ghostty is the terminal, and Omarchy only touches foot
    # when it is installed or chosen as the default.
    ++ builtins.filter (
      d: !(lib.hasPrefix "hyprland-" (d.name or "")) && !(lib.hasPrefix "foot-" (d.name or ""))
    ) cfg.package.passthru.runtimeDeps
    ++ (with pkgs; [
      glib
      gsettings-desktop-schemas
      gnome-themes-extra
      yaru-theme
      adwaita-icon-theme
      bibata-cursors
      wayvnc
      hyprland-preview-share-picker
    ]);

    environment.etc = {
      "omarchy/xcompose".source = "${cfg.package}/share/omarchy/default/xcompose";
      "chromium/policies/managed/omarchy-theme.json" = browserThemePolicy;
      "brave/policies/managed/omarchy-theme.json" = browserThemePolicy;
    }
    // lib.genAttrs installedEtc (name: {
      source = "${cfg.package}/share/omarchy/etc/${name}";
    });

    fonts.fontconfig.localConf = mkDefault (
      # From the source input, not the built tree: reading a build output here
      # would force a build during evaluation.
      builtins.readFile "${inputs.nixarchy.inputs.omarchy}/default/fontconfig/conf.avail/50-omarchy.conf"
    );
    fonts.packages = [
      cfg.package
    ]
    ++ (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      font-awesome
      liberation_ttf
      # Arch's ttf-ia-writer; Mono shows up in the Style > Font picker.
      ia-writer-mono
      ia-writer-duospace
      ia-writer-quattro
    ]);

    ##: Portals
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    ##: Lock screen (Quickshell) authenticates through this PAM service
    security.pam.services.omarchy-lock-password = { };
    security.rtkit.enable = true;
    security.polkit.enable = true;
    services.dbus.enable = true;

    ##: Audio - PipeWire stack
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    services.pulseaudio.enable = false;

    ##: Desktop services the Omarchy menus and bar talk to
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.udisks2.enable = mkDefault true;
    services.upower.enable = mkDefault true;
    services.power-profiles-daemon.enable = mkDefault (!config.services.tlp.enable);
    services.gnome.gnome-keyring.enable = mkDefault true;
    networking.networkmanager.enable = mkDefault true;
    hardware.bluetooth.enable = mkDefault true;
  };
}
