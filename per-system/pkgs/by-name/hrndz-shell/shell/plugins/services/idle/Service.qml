import QtQuick
import Quickshell
import Quickshell.Io

// Stay awake. hypridle (Home Manager) owns idle: lock, display off and the
// lock before sleep. While stay-awake is on, this holds a systemd idle
// inhibitor, which hypridle honours. The flag file keeps the choice across
// shell restarts.
Item {
  id: root

  // Injected by the first-party service loader.
  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stayAwakeStateDir: home + "/.local/state/hrndz-shell/indicators"
  readonly property string stayAwakeStatePath: stayAwakeStateDir + "/stay-awake"

  property bool stayAwake: false
  property bool stayAwakeStateLoaded: false
  readonly property bool idleEnabled: stayAwakeStateLoaded && !stayAwake

  function setIdleEnabled(value) {
    root.stayAwake = !value
    root.stayAwakeStateLoaded = true
    stateWriter.command = ["bash", "-c", value
      ? "rm -f \"$0/stay-awake\""
      : "mkdir -p \"$0\" && touch \"$0/stay-awake\"", root.stayAwakeStateDir]
    stateWriter.running = true
    return value ? "enabled" : "disabled"
  }

  function statusJson() {
    return JSON.stringify({
      enabled: root.idleEnabled,
      stayAwake: root.stayAwake,
      inhibiting: inhibitor.running
    })
  }

  Process {
    id: inhibitor
    running: root.stayAwake
    command: ["@systemdInhibit@", "--what=idle", "--who=hrndz-shell", "--why=Stay awake", "--mode=block", "sleep", "infinity"]
  }

  Process { id: stateWriter }

  Process {
    id: stateProbe
    running: true
    command: ["bash", "-c", "[[ -f $0 ]] && echo yes || echo no", root.stayAwakeStatePath]
    stdout: SplitParser {
      onRead: function(line) {
        root.stayAwake = String(line).trim() === "yes"
        root.stayAwakeStateLoaded = true
      }
    }
  }

  IpcHandler {
    target: "idle"

    function status(): string {
      return root.statusJson()
    }

    function enable(): string {
      return root.setIdleEnabled(true)
    }

    function disable(): string {
      return root.setIdleEnabled(false)
    }

    function toggle(): string {
      return root.setIdleEnabled(!root.idleEnabled)
    }
  }
}
