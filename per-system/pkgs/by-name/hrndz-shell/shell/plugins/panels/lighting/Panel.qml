import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// RGB lighting: one section per light that `rgb-lighting list` names (the
// NixOS openrgb hardware module declares them), with its modes and, for a
// mode that takes a colour, a colour picker. `rgb-lighting status` reads back
// the last choice per light.
Panel {
  id: root
  moduleName: "omarchy.lighting"
  ipcTarget: "omarchy.lighting"

  readonly property string command: "rgb-lighting"
  // Saturated colours: LEDs wash out pastel theme colours.
  readonly property var swatches: [
    "#FF0000", "#FF6000", "#FFC000", "#00FF40", "#00FFFF",
    "#0060FF", "#8000FF", "#FF00C0", "#FFFFFF"
  ]

  property var lights: []
  // name -> { mode, color }
  property var states: ({})
  property var pending: null
  property int cursorIndex: 0
  property bool cursorActive: false

  // Every mode button in panel order, for keyboard navigation.
  readonly property var buttons: {
    var out = []
    for (var i = 0; i < lights.length; i++)
      for (var j = 0; j < lights[i].modes.length; j++)
        out.push({ light: lights[i].name, mode: lights[i].modes[j] })
    return out
  }

  function refresh() {
    if (lights.length === 0 && !listProc.running) listProc.running = true
    if (!statusProc.running) statusProc.running = true
  }

  function updateStatus(raw) {
    var next = {}
    var lines = String(raw).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split(/\s+/)
      if (!parts[0]) continue
      next[parts[0]] = { mode: parts[1] || "", color: parts[2] ? "#" + parts[2].toUpperCase() : "" }
    }
    states = next
  }

  function stateOf(name) {
    return states[name] || { mode: "", color: "" }
  }

  function setState(name, mode, color) {
    var next = Object.assign({}, states)
    next[name] = { mode: mode, color: color }
    states = next
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

  function setMode(name, mode) {
    var color = stateOf(name).color
    setState(name, mode.id, color)
    run(mode.color && color ? [name, mode.id, color.slice(1)] : [name, mode.id])
  }

  function setColor(light, value) {
    var c = String(value).toUpperCase()
    if (!/^#[0-9A-F]{6}$/.test(c)) return
    var mode = colorMode(light)
    if (!mode) return
    setState(light.name, mode.id, c)
    run([light.name, mode.id, c.slice(1)])
  }

  function colorMode(light) {
    for (var i = 0; i < light.modes.length; i++)
      if (light.modes[i].color) return light.modes[i]
    return null
  }

  onOpenedChanged: if (opened) { cursorActive = false; refresh() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: listProc
    command: [root.command, "list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.lights = JSON.parse(text) } catch (e) { root.lights = [] }
      }
    }
  }

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
        var n = root.buttons.length
        if (n === 0) return
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.cursorIndex = (root.cursorIndex + (dx !== 0 ? dx : dy) + n) % n
      }
      onActivateRequested: {
        var b = root.buttons[root.cursorIndex]
        if (root.cursorActive && b) root.setMode(b.light, b.mode)
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Text {
          text: "Lighting"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Repeater {
          model: root.lights

          Column {
            id: section
            required property var modelData
            required property int index
            readonly property var light: modelData
            readonly property var lightState: root.stateOf(light.name)
            readonly property var colorMode: root.colorMode(light)
            // Index of this light's first button in root.buttons.
            readonly property int firstButton: {
              var n = 0
              for (var i = 0; i < index; i++) n += root.lights[i].modes.length
              return n
            }
            // The strip's marker; dragging moves it ahead of the saved colour.
            property real hue: 0
            function syncHue() { hue = Math.max(0, Qt.color(lightState.color || "#FF0000").hsvHue) }
            onLightStateChanged: syncHue()
            Component.onCompleted: syncHue()

            width: column.width
            spacing: Style.space(10)

            PanelSeparator {
              visible: section.index > 0
              foreground: root.bar.foreground
            }

            PanelSectionHeader {
              text: section.light.label.toUpperCase()
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Row {
              id: modeRow
              width: parent.width
              spacing: Style.space(6)
              readonly property real cellWidth: (width - spacing * (section.light.modes.length - 1)) / section.light.modes.length

              Repeater {
                model: section.light.modes
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
                  active: section.lightState.mode === modelData.id
                  hasCursor: root.cursorActive && root.cursorIndex === section.firstButton + index
                  onClicked: root.setMode(section.light.name, modelData)
                  onHovered: function(h) {
                    if (h) { root.cursorActive = true; root.cursorIndex = section.firstButton + index }
                  }
                }
              }
            }

            Row {
              id: swatchRow
              visible: !!section.colorMode
              width: parent.width
              spacing: Style.space(6)
              readonly property real cell: (width - spacing * (root.swatches.length - 1)) / root.swatches.length

              Repeater {
                model: root.swatches
                Rectangle {
                  required property string modelData
                  readonly property bool chosen: section.colorMode && section.lightState.mode === section.colorMode.id
                    && section.lightState.color === modelData
                  width: swatchRow.cell
                  height: Style.space(24)
                  radius: Style.cornerRadius
                  color: modelData
                  border.width: chosen ? 2 : 1
                  border.color: chosen
                    ? root.bar.foreground
                    : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.25)

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setColor(section.light, parent.modelData)
                  }
                }
              }
            }

            // Hue strip: drag to preview, release to apply.
            Rectangle {
              visible: !!section.colorMode
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
                x: Math.max(0, Math.min(parent.width - width, section.hue * parent.width - width / 2))
                color: "transparent"
                border.width: 2
                border.color: root.bar.foreground
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function hueAt(x) { return Math.max(0, Math.min(0.999, x / width)) }
                onPressed: function(e) { section.hue = hueAt(e.x) }
                onPositionChanged: function(e) { if (pressed) section.hue = hueAt(e.x) }
                onReleased: root.setColor(section.light, String(Qt.hsva(section.hue, 1, 1, 1)))
              }
            }

            Row {
              visible: !!section.colorMode
              width: parent.width
              spacing: Style.space(8)

              Rectangle {
                id: preview
                width: Style.space(30)
                height: hexField.height
                radius: Style.cornerRadius
                color: section.lightState.color || "transparent"
                border.width: 1
                border.color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.25)
              }

              TextField {
                id: hexField
                width: parent.width - preview.width - parent.spacing
                foreground: root.bar.foreground
                placeholderText: "#RRGGBB"
                text: section.lightState.color
                validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,6}/ }
                onAccepted: root.setColor(section.light, text.charAt(0) === "#" ? text : "#" + text)
              }
            }
          }
        }
      }
    }
  }
}
