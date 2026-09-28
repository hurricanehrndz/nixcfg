import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io

import qs.Commons

import "plugins/agents" as Agents
import "plugins/background" as Background
import "plugins/bar"
import "plugins/bar/widgets" as Widgets
import "plugins/clipboard" as Clipboard
import "plugins/emojis" as Emojis
import "plugins/menu" as Menu
import "plugins/notifications" as Notifications
import "plugins/osd" as Osd
import "plugins/panels/audio" as Audio
import "plugins/panels/bluetooth" as Bluetooth
import "plugins/panels/clock" as Clock
import "plugins/panels/monitor" as Monitor
import "plugins/panels/network" as Network
import "plugins/panels/power" as Power
import "plugins/panels/tailscale" as Tailscale
import "plugins/panels/weather" as Weather
import "plugins/services/battery" as Battery
import "plugins/services/idle" as Idle
import "plugins/services/media" as Media
import "plugins/services/nightlight" as Nightlight
import "services"
import "services/AuthServiceStore.js" as AuthServiceStore

ShellRoot {
  id: shell

  // Shared service instances. Plugins receive these via property injection
  // rather than re-importing them as singletons — relative-path imports do
  // not share singleton state, which silently leaves consumers with their
  // own empty copies.
  property AppLibrary appLibrary: AppLibrary { omarchyPath: shell.omarchyPath }

  property string home: Quickshell.env("HOME")

  // The package's share dir; package.nix substitutes it.
  property string omarchyPath: "@shareDir@"
  // Home Manager writes the whole config (bar layout, plugins); the
  // shell never writes it. What the UI changes at runtime (per-widget
  // settings such as tray pins or clock format) goes to the overlay, keyed by
  // entry id, and is laid over the Nix config on load.
  readonly property string defaultsPath: home + "/.config/hrndz-shell/shell.json"
  readonly property string userConfigPath: home + "/.local/state/hrndz-shell/settings.json"

  // Bundled fallback so the shell can start even when the Nix config is
  // missing or unreadable.
  readonly property var builtinShellConfig: ({
    version: 1,
    bar: {
      position: "top",
      transparent: false,
      centerAnchor: "omarchy.clock",
      layout: {
        left: [{ id: "omarchy.menu" }, { id: "omarchy.workspaces" }],
        center: [{ id: "omarchy.clock", format: "dddd HH:mm" }],
        right: [{ id: "omarchy.audio" }]
      }
    },
    plugins: []
  })

  property var defaultsConfig: builtinShellConfig
  property var shellConfig: builtinShellConfig

  // Every entry in the bar layout and plugins[], in order.
  function configEntries(config) {
    var out = []
    var layout = config && config.bar && Util.isPlainObject(config.bar.layout) ? config.bar.layout : {}
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var arr = Array.isArray(layout[sections[s]]) ? layout[sections[s]] : []
      for (var i = 0; i < arr.length; i++) if (Util.isPlainObject(arr[i])) out.push(arr[i])
    }
    var plugins = config && Array.isArray(config.plugins) ? config.plugins : []
    for (var j = 0; j < plugins.length; j++) if (Util.isPlainObject(plugins[j])) out.push(plugins[j])
    return out
  }

  // CEILING: overlay settings are keyed by entry id, so two instances of one
  // allowMultiple widget share them. Key by section and index if that is
  // ever needed.
  function applyShellConfig() {
    var defaults = Util.isPlainObject(defaultsConfig) ? defaultsConfig : builtinShellConfig
    var merged = JSON.parse(JSON.stringify(defaults))
    var overlay = null
    var overlayText = userConfigFile.text() || ""
    if (overlayText.trim()) {
      try {
        var parsed = JSON.parse(overlayText)
        if (Util.isPlainObject(parsed) && Util.isPlainObject(parsed.entries)) overlay = parsed.entries
      } catch (e) {
        console.warn("settings overlay parse failed, ignoring:", e)
      }
    }
    if (overlay) {
      var entries = configEntries(merged)
      for (var i = 0; i < entries.length; i++) {
        var settings = overlay[Util.canonicalWidgetId(entries[i].id)]
        if (!Util.isPlainObject(settings)) continue
        for (var k in settings) if (k !== "id") entries[i][k] = settings[k]
      }
    }
    shellConfig = merged
  }

  function loadDefaults(raw) {
    var text = String(raw || "").trim()
    if (!text) {
      defaultsConfig = builtinShellConfig
      applyShellConfig()
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (Util.isPlainObject(parsed) && parsed.version === 1) defaultsConfig = parsed
      else defaultsConfig = builtinShellConfig
    } catch (e) {
      console.warn("shell.json parse failed, using builtin:", e)
      defaultsConfig = builtinShellConfig
    }
    applyShellConfig()
  }

  // Layout, position and transparency changes made in the UI apply until the
  // next restart; only per-entry settings that differ from the Nix config are
  // persisted.
  function persistShellConfig(nextConfig) {
    var payload = JSON.parse(JSON.stringify(nextConfig))
    payload.version = 1
    shellConfig = payload

    var defaults = {}
    var defaultEntries = configEntries(Util.isPlainObject(defaultsConfig) ? defaultsConfig : builtinShellConfig)
    for (var i = 0; i < defaultEntries.length; i++) defaults[Util.canonicalWidgetId(defaultEntries[i].id)] = defaultEntries[i]
    var overlay = {}
    var entries = configEntries(payload)
    for (var j = 0; j < entries.length; j++) {
      var id = Util.canonicalWidgetId(entries[j].id)
      var base = defaults[id] || {}
      for (var k in entries[j]) {
        if (k === "id" || JSON.stringify(entries[j][k]) === JSON.stringify(base[k])) continue
        if (!overlay[id]) overlay[id] = {}
        overlay[id][k] = entries[j][k]
      }
    }
    userConfigFile.setText(JSON.stringify({ entries: overlay }, null, 2) + "\n")
  }

  readonly property var barConfig: shellConfig && Util.isPlainObject(shellConfig.bar) ? shellConfig.bar : builtinShellConfig.bar

  FileView {
    id: defaultsFile
    path: shell.defaultsPath
    watchChanges: true
    printErrors: false
    onLoaded: shell.loadDefaults(text())
    onLoadFailed: function(error) {
      console.warn("shell.json load failed: " + error + " path=" + shell.defaultsPath)
      shell.loadDefaults("")
    }
    onFileChanged: reload()
  }

  FileView {
    id: userConfigFile
    path: shell.userConfigPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: shell.applyShellConfig()
    onLoadFailed: function(error) { shell.applyShellConfig() }
    onFileChanged: reload()
  }

  Component.onCompleted: {
    console.log("hrndz-shell paths",
      "omarchyPath=" + shell.omarchyPath,
      "shellDir=" + Quickshell.shellDir,
      "defaultsPath=" + shell.defaultsPath,
      "userConfigPath=" + shell.userConfigPath)
    shell.startAuthenticationService("omarchy.lock", "plugins/lock/Service.qml")
    shell.startAuthenticationService("omarchy.polkit", "plugins/polkit/PolkitAgent.qml")
  }

  // The bar's layout edits (drag to reorder, edge, transparency) go through
  // here; see persistShellConfig for what survives a restart.
  function mutateShellConfig(mutator) {
    var copy = JSON.parse(JSON.stringify(shellConfig || builtinShellConfig))
    mutator(copy)
    persistShellConfig(copy)
  }

  // Exposed so child plugins (notifications, future panels) can read
  // barSize/barHidden/position to anchor relative to the bar.
  readonly property alias bar: barInstance

  Bar {
    id: barInstance
    omarchyPath: shell.omarchyPath
    barWidgetRegistry: ({ widgets: shell.barWidgets })
    barConfig: shell.barConfig
    shell: shell
  }

  // ------------------------------------------------------------- services

  Item {
    id: serviceHost
    visible: false

    Background.Background { }
    Notifications.Service { shell: shell; omarchyPath: shell.omarchyPath }
    Battery.Service { shell: shell }
    Idle.Service { shell: shell }
    Media.Service { shell: shell }
    Nightlight.Service { shell: shell }
  }

  // Lock and polkit handle credentials, so they get no QObject parent and no
  // property on the shell: nothing can walk the object tree to them. The
  // private JS import keeps them alive.
  function startAuthenticationService(id, path) {
    // A file URL: under Quickshell's qs: scheme the service's own directory
    // does not resolve as an implicit import.
    var comp = Qt.createComponent(Util.fileUrl(shell.omarchyPath + "/shell/" + path), Component.PreferSynchronous)
    function finalize() {
      if (comp.status !== Component.Ready) {
        console.warn("authentication service " + id + " failed to load: " + comp.errorString())
        return
      }
      var inst = comp.createObject(null)
      if (!inst) {
        console.warn("authentication service createObject returned null for", id)
        return
      }
      if ("omarchyPath" in inst) inst.omarchyPath = shell.omarchyPath
      if ("shell" in inst) inst.shell = shell
      AuthServiceStore.put(id, inst)
    }
    if (comp.status === Component.Loading) comp.statusChanged.connect(finalize)
    else finalize()
  }

  // ------------------------------------------------------------- windows

  // Summoned over IPC (summon/hide/toggle/call); each keeps its own
  // `opened` state and takes a JSON payload in open().
  Clipboard.Clipboard { id: clipboardWindow; omarchyPath: shell.omarchyPath }
  Emojis.Emojis { id: emojisWindow; omarchyPath: shell.omarchyPath; shell: shell }
  Menu.Menu { id: menuWindow; omarchyPath: shell.omarchyPath; shell: shell }
  Osd.Osd { id: osdWindow }

  readonly property var windows: ({
    "omarchy.clipboard": clipboardWindow,
    "omarchy.emojis": emojisWindow,
    "omarchy.menu": menuWindow,
    "omarchy.osd": osdWindow
  })

  // ------------------------------------------------------------- bar widgets

  // The widgets shell.json's bar layout can name. Their panels open from the
  // bar, so summon/hide/toggle route to the live bar instance.
  readonly property var barWidgets: ({
    "omarchy.active-window": { component: activeWindowWidget },
    "omarchy.agents": { component: agentsWidget },
    "omarchy.audio": { component: audioWidget },
    "omarchy.bluetooth": { component: bluetoothWidget },
    "omarchy.clock": { component: clockWidget },
    "omarchy.indicators": { component: indicatorsWidget },
    "omarchy.media": { component: mediaWidget },
    "omarchy.menu": { component: menuWidget },
    "omarchy.microphone": { component: microphoneWidget },
    "omarchy.monitor": { component: monitorWidget },
    "omarchy.network": { component: networkWidget },
    "omarchy.power": { component: powerWidget },
    "omarchy.spacer": { component: spacerWidget },
    "omarchy.tailscale": { component: tailscaleWidget },
    "omarchy.tray": { component: trayWidget },
    "omarchy.weather": { component: weatherWidget },
    "omarchy.workspaces": { component: workspacesWidget }
  })

  Component { id: activeWindowWidget; Widgets.ActiveWindow { } }
  Component { id: agentsWidget; Agents.Panel { } }
  Component { id: audioWidget; Audio.Panel { } }
  Component { id: bluetoothWidget; Bluetooth.Panel { } }
  Component { id: clockWidget; Clock.BarWidget { } }
  Component { id: indicatorsWidget; Widgets.Indicators { } }
  Component { id: mediaWidget; Media.BarWidget { } }
  Component { id: menuWidget; Menu.BarWidget { } }
  Component { id: microphoneWidget; Widgets.Microphone { } }
  Component { id: monitorWidget; Monitor.Panel { } }
  Component { id: networkWidget; Network.Panel { } }
  Component { id: powerWidget; Power.Panel { } }
  Component { id: spacerWidget; Widgets.Spacer { } }
  Component { id: tailscaleWidget; Tailscale.Panel { } }
  Component { id: trayWidget; Widgets.Tray { } }
  Component { id: weatherWidget; Weather.BarWidget { } }
  Component { id: workspacesWidget; Widgets.Workspaces { } }

  // Writes inline settings to a bar layout entry or top-level plugin entry in
  // shell.json. moduleName is the entry id; settings is the merged plugin
  // state. Returns true if anything actually changed. Compute the proposed
  // new shellConfig in a local clone, and only persist if anything actually
  // changed so reactive bindings do not dirty shell.json unnecessarily.
  function updateEntryInline(moduleName, settings) {
    var stripped = Util.canonicalWidgetId(moduleName)
    var copy = JSON.parse(JSON.stringify(shellConfig || builtinShellConfig))
    if (!Util.isPlainObject(copy.bar)) copy.bar = { layout: { left: [], center: [], right: [] } }
    if (!Util.isPlainObject(copy.bar.layout)) copy.bar.layout = { left: [], center: [], right: [] }
    if (!Array.isArray(copy.plugins)) copy.plugins = []

    var sections = ["left", "center", "right"]
    var foundInLayout = false
    var dirty = false
    for (var s = 0; s < sections.length; s++) {
      var arr = copy.bar.layout[sections[s]] || []
      for (var i = 0; i < arr.length; i++) {
        if (arr[i] && Util.canonicalWidgetId(arr[i].id) === stripped) {
          var next = { id: stripped }
          for (var k in settings) if (k !== "id") next[k] = settings[k]
          if (JSON.stringify(arr[i]) !== JSON.stringify(next)) {
            arr[i] = next
            dirty = true
          }
          foundInLayout = true
        }
      }
    }
    if (!foundInLayout) {
      for (var j = 0; j < copy.plugins.length; j++) {
        if (copy.plugins[j] && copy.plugins[j].id === stripped) {
          var pnext = { id: stripped }
          for (var pk in settings) if (pk !== "id") pnext[pk] = settings[pk]
          if (JSON.stringify(copy.plugins[j]) !== JSON.stringify(pnext)) {
            copy.plugins[j] = pnext
            dirty = true
          }
        }
      }
    }
    if (!dirty) return false
    persistShellConfig(copy)
    return true
  }

  // ---------------------------------------------------------- summoning

  function summon(pluginId, payloadJson) {
    var id = Util.canonicalWidgetId(pluginId)
    var window = windows[id]
    if (window) {
      window.open(payloadJson || "")
      return true
    }
    if (!barWidgets[id]) {
      console.warn("summon: unknown plugin", id)
      return false
    }
    // Bar widgets take no payload; payloadJson is dropped on this path.
    var summoned = shell.bar.summonBarWidget(id)
    if (!summoned) console.warn("summon: no live bar widget for:", id)
    return summoned === true
  }

  function hide(pluginId) {
    var id = Util.canonicalWidgetId(pluginId)
    var window = windows[id]
    if (window) {
      window.close()
      return true
    }
    var hidden = barWidgets[id] && shell.bar.hideBarWidget(id)
    if (!hidden) console.warn("hide: no live bar widget for:", id)
    return hidden === true
  }

  function isPluginOpen(pluginId) {
    var id = Util.canonicalWidgetId(pluginId)
    var window = windows[id]
    if (window) return window.opened === true
    return barWidgets[id] ? shell.bar.isBarWidgetOpen(id) : false
  }

  function toggle(pluginId, payloadJson) {
    return isPluginOpen(pluginId) ? hide(pluginId) : summon(pluginId, payloadJson)
  }

  function callIfLoaded(pluginId, method, arg) {
    var id = Util.canonicalWidgetId(pluginId)
    var window = windows[id]
    if (!window || typeof window[method] !== "function") return "unknown"
    try {
      var result = window[method](arg)
      return result === undefined || result === null ? "ok" : String(result)
    } catch (e) {
      console.warn("plugin " + id + " " + method + "() threw:", e)
      return "error"
    }
  }

  // ---------------------------------------------------------- shell IPC

  IpcHandler {
    target: "shell"

    function ping(): string {
      return "ok"
    }

    function reloadConfig(): string {
      userConfigFile.reload()
      return "ok"
    }

    function toggleBarTransparency(): string {
      shell.bar.toggleTransparency()
      return "ok"
    }

    // Returns the effective shell.json content as JSON. Useful for debugging
    // and for CLI tools that want to inspect the merged state without
    // re-implementing the load logic.
    function listShellConfig(): string {
      return JSON.stringify(shell.shellConfig || {})
    }

    function debugBarGeometry(): string {
      return JSON.stringify(shell.bar.debugBarGeometry())
    }

    function summon(id: string, payloadJson: string): string {
      return shell.summon(id, payloadJson) ? "ok" : "unknown"
    }

    function hide(id: string): void {
      shell.hide(id)
    }

    function toggle(id: string, payloadJson: string): void {
      shell.toggle(id, payloadJson)
    }

    // A bar section's panels answer to their position as well as their id, so a
    // hotkey can mean "the third panel in the right section" and keep meaning
    // it after the bar is rearranged. Returns the id it acted on, or "unknown"
    // when the section holds no panel at that position.
    function togglePanelAt(section: string, index: string): string {
      var id = shell.bar.panelWidgetIdAt(section, index)
      if (!id) return "unknown"
      shell.toggle(id, "{}")
      return id
    }

    function call(id: string, method: string, arg: string): string {
      return shell.callIfLoaded(id, method, arg)
    }
  }
}
