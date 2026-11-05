import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "urban.workspaces"

  // Omarchy gives each monitor its own block of ten workspace ids (left 1-10,
  // right 11-20; see default/hypr/monitor-workspaces.lua). Super + 1-5 and 6-0
  // use slots 1-5 of the left and right blocks (see ~/.config/hypr/bindings.lua),
  // so each bar shows its block's first five and labels them by key.
  readonly property var monitor: {
    var window = root.QsWindow.window
    var screen = window ? window.screen : null
    return screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  }
  readonly property string monitorName: root.monitor ? root.monitor.name : ""

  // Connector -> block, from the file Hyprland keeps them in.
  property var blocks: ({})

  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/monitors/workspaces"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var next = {}
      var lines = String(text() || "").split("\n")
      for (var i = 0; i < lines.length; i++) {
        var fields = lines[i].split("\t")
        if (fields.length >= 3 && fields[1] !== "") next[fields[1]] = parseInt(fields[0], 10)
      }
      root.blocks = next
    }
  }

  function activeWorkspaceId() {
    return root.monitor && root.monitor.activeWorkspace ? root.monitor.activeWorkspace.id : -1
  }

  readonly property int block: {
    var block = root.blocks[root.monitorName]
    if (block !== undefined) return block
    var active = root.activeWorkspaceId()
    return active > 0 ? Math.floor((active - 1) / 10) : 0
  }
  readonly property int blockStart: root.block * 10

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  // The first five of this monitor's block, plus any other workspace on it.
  function workspaceIds() {
    var first = root.blockStart + 1
    var ids = [first, first + 1, first + 2, first + 3, first + 4]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      var onThisScreen = values[i].monitor && values[i].monitor.name === root.monitorName
      if (id > 0 && onThisScreen && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function label(id) {
    var slot = id - root.blockStart
    if (slot < 1 || slot > 5) return String(id)
    var key = root.block * 5 + slot
    return key === 10 ? "0" : String(key)
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    var slot = id - root.blockStart
    var command = slot >= 1 && slot <= 10
      ? "o.workspaces.focus(" + slot + ", \"" + root.monitorName + "\")"
      : "hl.dsp.focus({ workspace = \"" + id + "\" })"
    root.bar.run("hyprctl dispatch " + Util.shellQuote(command))
  }

  // Quickshell credits every workspace switch to the focused monitor and misses
  // switches on the others, so ask Hyprland for the truth (as the stock widget does).
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      var switched = name === "workspacev2" && root.monitor !== null && root.monitor.focused
      if (switched || name === "focusedmonv2" || name === "moveworkspacev2" || name === "changeworkspaceid" || name === "configreloaded") {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
      }
    }
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: root.monitor !== null && root.monitor.activeWorkspace !== null && root.monitor.activeWorkspace.id === modelData

        bar: root.bar
        text: focused ? "󱓻" : root.label(modelData)
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
