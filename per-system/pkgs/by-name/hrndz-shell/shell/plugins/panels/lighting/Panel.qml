import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Soundbar lighting: the modes the soundbar runs itself, and a colour for
// Static. `leviathan-lighting` (NixOS hardware module) talks to OpenRGB and
// remembers the last choice, which is what `status` reads back.
Panel {
  id: root
  moduleName: "omarchy.lighting"
  ipcTarget: "omarchy.lighting"

  readonly property string command: "leviathan-lighting"
  readonly property var modes: [
    { id: "breathing", label: "Breathe" },
    { id: "spectrum", label: "Spectrum" },
    { id: "wave", label: "Wave" },
    { id: "static", label: "Static" },
    { id: "off", label: "Off" }
  ]
  // Saturated colours: LEDs wash out pastel theme colours.
  readonly property var swatches: [
    "#FF0000", "#FF6000", "#FFC000", "#00FF40", "#00FFFF",
    "#0060FF", "#8000FF", "#FF00C0", "#FFFFFF"
  ]

  property string mode: ""
  property string staticColor: ""
  property real hue: 0
  property int cursorIndex: 0
  property bool cursorActive: false
  property var pending: null

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function updateStatus(raw) {
    var parts = String(raw).trim().split(/\s+/)
    mode = parts[0] || ""
    if (parts[1]) {
      staticColor = "#" + parts[1].toUpperCase()
      hue = Math.max(0, Qt.color(staticColor).hsvHue)
    }
  }

  // One change at a time: each takes about a second, so a click that lands
  // while one runs replaces whatever was still waiting.
  function run(args) {
    if (actionProc.running) {
      pending = args
      return
    }
    actionProc.command = [root.command].concat(args)
    actionProc.running = true
  }

  function setMode(id) {
    mode = id
    run(id === "static" && staticColor ? ["static", staticColor.slice(1)] : [id])
  }

  function setColor(value) {
    var c = String(value).toUpperCase()
    if (!/^#[0-9A-F]{6}$/.test(c)) return
    staticColor = c
    mode = "static"
    run(["static", c.slice(1)])
  }

  function hexOf(c) {
    return String(c).toUpperCase()
  }

  onOpenedChanged: if (opened) { cursorActive = false; refresh() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: statusProc
    command: [root.command, "status"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateStatus(text) }
  }

  Process {
    id: actionProc
    onExited: {
      if (root.pending) {
        var next = root.pending
        root.pending = null
        root.run(next)
      } else {
        root.refresh()
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌵"
    tooltipText: ""
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        var n = root.modes.length
        root.cursorIndex = (root.cursorIndex + (dx !== 0 ? dx : dy) + n) % n
      }
      onActivateRequested: if (root.cursorActive) root.setMode(root.modes[root.cursorIndex].id)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Text {
          text: "Soundbar lighting"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "MODE"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: modeRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * (root.modes.length - 1)) / root.modes.length

            Repeater {
              model: root.modes
              Button {
                required property var modelData
                required property int index
                width: modeRow.cellWidth
                text: modelData.label
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.space(4)
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: root.mode === modelData.id
                hasCursor: root.cursorActive && root.cursorIndex === index
                onClicked: root.setMode(modelData.id)
                onHovered: function(h) {
                  if (h) { root.cursorActive = true; root.cursorIndex = index }
                }
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "STATIC COLOUR"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: swatchRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cell: (width - spacing * (root.swatches.length - 1)) / root.swatches.length

            Repeater {
              model: root.swatches
              Rectangle {
                required property string modelData
                width: swatchRow.cell
                height: Style.space(24)
                radius: Style.cornerRadius
                color: modelData
                border.width: root.mode === "static" && root.staticColor === modelData ? 2 : 1
                border.color: root.mode === "static" && root.staticColor === modelData
                  ? root.bar.foreground
                  : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.25)

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setColor(parent.modelData)
                }
              }
            }
          }

          // Hue strip: drag to preview, release to apply.
          Rectangle {
            id: hueStrip
            width: parent.width
            height: Style.space(18)
            radius: height / 2
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0 / 6; color: "#FF0000" }
              GradientStop { position: 1 / 6; color: "#FFFF00" }
              GradientStop { position: 2 / 6; color: "#00FF00" }
              GradientStop { position: 3 / 6; color: "#00FFFF" }
              GradientStop { position: 4 / 6; color: "#0000FF" }
              GradientStop { position: 5 / 6; color: "#FF00FF" }
              GradientStop { position: 6 / 6; color: "#FF0000" }
            }

            Rectangle {
              width: Style.space(6)
              height: parent.height + Style.space(6)
              radius: width / 2
              anchors.verticalCenter: parent.verticalCenter
              x: Math.max(0, Math.min(parent.width - width, root.hue * parent.width - width / 2))
              color: "transparent"
              border.width: 2
              border.color: root.bar.foreground
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              function hueAt(x) { return Math.max(0, Math.min(0.999, x / width)) }
              onPressed: function(e) { root.hue = hueAt(e.x) }
              onPositionChanged: function(e) { if (pressed) root.hue = hueAt(e.x) }
              onReleased: root.setColor(root.hexOf(Qt.hsva(root.hue, 1, 1, 1)))
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            Rectangle {
              id: preview
              width: Style.space(30)
              height: hexField.height
              radius: Style.cornerRadius
              color: root.staticColor || "transparent"
              border.width: 1
              border.color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.25)
            }

            TextField {
              id: hexField
              width: parent.width - preview.width - parent.spacing
              foreground: root.bar.foreground
              placeholderText: "#RRGGBB"
              text: root.staticColor
              validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,6}/ }
              onAccepted: root.setColor(text.charAt(0) === "#" ? text : "#" + text)
            }
          }
        }
      }
    }
  }
}
