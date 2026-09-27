// Workspace buttons: the named (Meh+letter) workspaces in binding order,
// then any numbered workspace 1-10 that exists. Upstream showed only ids
// 1-10, and Hyprland gives named workspaces negative ids, so the named ones
// never appeared.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  // The named workspaces, in binding order, from this entry's `named`
  // setting (Home Manager fills it from the keybindings' list).
  readonly property var namedWorkspaces: setting("named", [])

  function workspaceByName(name) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].name === name) return values[i]
    }

    return null
  }

  function entries() {
    var list = []
    for (var i = 0; i < namedWorkspaces.length; i++) {
      var letter = namedWorkspaces[i]
      list.push({ name: letter, label: letter, target: "name:" + letter })
    }

    var ids = []
    var values = Hyprland.workspaces.values
    for (var j = 0; j < values.length; j++) {
      var id = values[j].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    for (var k = 0; k < ids.length; k++) {
      list.push({ name: String(ids[k]), label: ids[k] === 10 ? "0" : String(ids[k]), target: String(ids[k]) })
    }

    return list
  }

  function focusWorkspace(target) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + target + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.entries().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.entries()

      WidgetButton {
        required property var modelData

        readonly property var workspace: root.workspaceByName(modelData.name)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.name === modelData.name

        bar: root.bar
        text: focused ? "󱓻" : modelData.label
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData.target) }
      }
    }
  }
}
