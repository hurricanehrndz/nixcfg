{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz.desktop.hyprland;

  # On-demand VNC into the desktop, mostly for agents and rare checks.
  # Attaches to a running session, or starts a seatless one (libseat noop:
  # the GPU is opened with the user's video-group access, so no login or
  # monitor is needed). Adds a virtual output only when no display is plugged
  # in. VNC listens on localhost only; reach it through an SSH tunnel.
  desktopVnc = pkgs.writeShellApplication {
    name = "desktop-vnc";
    runtimeInputs = [
      config.programs.hyprland.package
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
      session_unit=hyprland-headless
      vnc_unit=desktop-vnc
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      state="$XDG_RUNTIME_DIR/desktop-vnc"

      usage() {
        echo "usage: desktop-vnc start|stop|status"
        echo
        echo "  start   attach to (or start) the Hyprland session and serve it over VNC"
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

      # A monitor is plugged in, so a session started here is visible on it.
      # TODO(phase2): lock through the forked shell's lock screen before
      # anything is served; until then this only warns.
      lock_session() {
        echo "desktop-vnc: no lock screen yet; this session is visible on the attached display." >&2
      }

      start_session() {
        echo "No Hyprland session running; starting a headless one."
        # Like the login session, Hyprland reads the Home Manager config at
        # ~/.config/hypr/hyprland.lua.
        systemctl --user reset-failed "$session_unit" 2>/dev/null || true
        systemd-run --user --quiet --unit="$session_unit" \
          -E LIBSEAT_BACKEND=noop \
          -E XDG_SESSION_TYPE=wayland \
          -E XDG_CURRENT_DESKTOP=Hyprland \
          -E XDG_SESSION_DESKTOP=Hyprland \
          start-hyprland
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
          if display_connected; then
            lock_session
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
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [
      desktopVnc
      pkgs.wayvnc
    ];
  };
}
