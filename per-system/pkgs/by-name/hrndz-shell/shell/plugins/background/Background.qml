import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui

// The desktop background and the screensaver, on every output. The
// background is the ambient still (see Commons/Ambient.qml), so it costs
// nothing once drawn. hypridle raises the screensaver over everything on
// idle, playing the video from that same frame, and drops it on input; the
// lock follows at its own timeout.
Item {
  id: root

  Variants {
    model: Quickshell.screens

    Scope {
      id: output
      required property var modelData

      PanelWindow {
        id: panel
        screen: output.modelData
        visible: !remapGuard.remapping
        anchors { top: true; bottom: true; left: true; right: true }
        color: Color.background

        ScreenMoveRemap {
          id: remapGuard
          window: panel
        }

        WlrLayershell.namespace: "omarchy-background"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        AmbientView {
          anchors.fill: parent
        }
      }

      PanelWindow {
        id: screensaver
        screen: output.modelData
        visible: Ambient.screensaver && !Ambient.locked
        anchors { top: true; bottom: true; left: true; right: true }
        color: Color.background

        WlrLayershell.namespace: "hrndz-screensaver"
        WlrLayershell.layer: WlrLayer.Overlay
        // Takes the keys so the first press only dismisses.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        AmbientView {
          anchors.fill: parent
          focus: true
          video: screensaver.visible
          playing: Ambient.displaysOn
          // The first output's playback is the one the lock screen resumes.
          publishPosition: output.modelData === Quickshell.screens[0]
          // Dismissed after the event is delivered: hiding drops the video
          // items, and Qt 6.11 then maps its synthesized context-menu event
          // (right button, Menu key) through the freed items and crashes.
          Keys.onPressed: Qt.callLater(() => Ambient.screensaver = false)

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: Qt.callLater(() => Ambient.screensaver = false)
          }
        }
      }
    }
  }
}
