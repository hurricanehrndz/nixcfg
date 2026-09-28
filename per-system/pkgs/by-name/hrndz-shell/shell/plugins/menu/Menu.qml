import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "MenuModel.js" as MenuModel

Item {
  id: root

  // Injected by the shell when this plugin is summoned.
  property string omarchyPath: ""
  property var shell: null
  property var manifest: null

  // Plugin lifecycle hooks. The host calls open(payloadJson) after
  // `hrndz-shell ipc shell summon omarchy.menu ...` and close() when hidden.
  property string pendingInitialMenu: "root"

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }

    if (payload.fontFamily) root.fontFamily = payload.fontFamily

    if (payload.mode === "select" || payload.mode === "input") {
      root.openDmenu(payload)
    } else {
      root.openRoute(payload.initialMenu || payload.menu || "root")
    }
  }

  function close() {
    root.cancel()
  }

  function refresh() {
    defaultMenuFile.reload()
    return "ok"
  }

  function ping() { return "ok" }

  property string fontFamily: Style.font.menuFamily
  // The JSONC menu definition, shipped with the package and parsed at
  // startup, so the keybind → IPC → visible path doesn't shell out on open.
  property string defaultMenuPath: omarchyPath + "/menu.jsonc"
  property var defaultMenuItems: []
  property bool opened: false
  property string mode: "menu"
  readonly property bool dmenuActive: mode === "select" || mode === "input"
  property string dmenuPrompt: ""
  property var dmenuOptions: []
  property string selectionFile: ""
  property string doneFile: ""
  property int dmenuWidth: 300
  property int dmenuMaxHeight: 0
  property bool requestActive: false
  property bool rowsLoaded: false
  property string activeMenu: "root"
  property string filterText: ""
  onFilterTextChanged: if (searchField && searchField.text !== filterText) searchField.text = filterText
  property int selectedIndex: 0
  property bool cursorActive: false
  property int requestSerial: 0
  property int applySerial: 0
  property var items: ({})
  property var itemOrder: []
  property var navStack: []
  property bool appsLoaded: false

  // Shared application engine (entries, hidden filters, icons, launch,
  // feedback), owned by the shell.
  readonly property var appLibrary: root.shell ? root.shell.appLibrary : null
  onAppLibraryChanged: if (root.opened && (root.activeMenu === "root" || root.activeMenu === "apps")) root.loadApps()
  // Bound to the central [menu] section in shell.toml via Color.qml.
  // Each color already includes its alpha companion (composed in the
  // singleton), so consumers can drop them straight into a Rectangle.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color selectedBorder: Color.menu.selectedBorder
  property var selectedBorderSpec: Border.surfaceSpec("menu", "selected-border", selectedBorder, 0)
  readonly property real rowReservedBorderLeft: Border.left(selectedBorderSpec)
  readonly property real rowReservedBorderRight: Border.right(selectedBorderSpec)
  readonly property int cornerRadius: Style.cornerRadius
  readonly property color accent: Color.accent
  readonly property color muted: Util.alpha(root.foreground, 0.55)
  readonly property color hairline: Util.alpha(root.foreground, 0.1)
  property int headerHeight: Style.space(62)
  property int crumbHeight: Style.space(30)
  property int footerHeight: Style.space(44)
  // Vertical room around the rows: the gap under the header and above the
  // footer (or the card's bottom edge for a dmenu picker).
  property int listInset: Style.space(10)
  property int baseRowHeight: Math.max(Style.space(44), Style.font.heading + Style.spacing.rowPaddingX * 2)
  property int detailRowHeight: Math.max(Style.space(54), Style.font.heading + Style.font.bodySmall + Style.spacing.rowPaddingX * 2)
  // How much of the first hidden row stays visible at the fold — enough to
  // read as a cut-off row rather than a bottom border.
  property int rowPeek: Math.round(baseRowHeight * 0.55)
  property int rowSpacing: Style.spacing.xs
  property int dividerHeight: Style.space(17)
  property int layoutSerial: 0
  // A dmenu picker is sized by its caller and its rows; the palette is sized
  // by the output (paletteRect).
  property int dmenuCardWidth: Math.min(Style.space(root.dmenuWidth), panel.width - Style.gapsOut * 2)
  property int visibleRowsHeight: root.dmenuActive ? dmenuRowListHeight(layoutSerial, displayModel.count, filterText) : 0
  property int dmenuCardHeight: Math.min(headerHeight + (mode === "input" ? 0 : 1 + listInset * 2 + visibleRowsHeight), panel.height - Style.gapsOut * 2)

  // The palette card grows with the output, 40% × 54% of it, between the
  // base size and 1.5× it, so a wide monitor gets a wide palette instead of
  // a narrow column. It sits a little above centre and clear of the bar.
  // Adapted from olafkfreund/nixarchy-menu core/Geometry.js (MIT), rev
  // 2cce175c6ffd4747dc42f571760071dc2650282f.
  function paletteRect(outW, outH, bar) {
    function reserve(edge) { return bar && !bar.barHidden && bar.position === edge ? bar.barSize : 0 }
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
    var baseW = Style.space(640), baseH = Style.space(520), margin = Style.space(16)
    var availW = outW - reserve("left") - reserve("right") - 2 * margin
    var availH = outH - reserve("top") - reserve("bottom") - 2 * margin
    var width = Math.min(availW, clamp(Math.round(0.40 * outW), baseW, 1.5 * baseW))
    var height = Math.min(availH, clamp(Math.round(0.54 * outH), baseH, 1.5 * baseH))
    return {
      x: reserve("left") + margin + Math.round((availW - width) / 2),
      y: reserve("top") + margin + Math.round((availH - height) * 0.38),
      width: width,
      height: height
    }
  }

  // The row under the cursor, for the footer. Reads layoutSerial so it
  // follows a rebuilt model as well as a moved cursor.
  readonly property var currentRow: {
    root.layoutSerial
    return displayModel.count > 0 && root.selectedIndex < displayModel.count ? displayModel.get(root.selectedIndex) : null
  }
  readonly property string currentVerb: {
    var row = root.currentRow
    if (!row) return ""
    if (row.kind === "menu" || row.kind === "link" || row.kind === "app") return "Open"
    return "Run"
  }
  readonly property string crumbText: {
    if (root.filterText) return "Search results"
    if (root.activeMenu !== "root") return root.pathFor(root.activeMenu)
    return "Apps and actions · type to search"
  }

  function finishRequest(selection) {
    if (!root.requestActive || !root.doneFile) {
      root.opened = false
      return
    }

    var activeSelectionFile = root.selectionFile
    var activeDoneFile = root.doneFile
    root.requestActive = false
    root.selectionFile = ""
    root.doneFile = ""

    if (selection === null || selection === undefined) {
      resultProc.command = ["bash", "-c", ": > " + Util.shellQuote(activeDoneFile)]
    } else {
      resultProc.command = ["bash", "-c", "printf '%s\\n' " + Util.shellQuote(selection) + " > " + Util.shellQuote(activeSelectionFile) + "; : > " + Util.shellQuote(activeDoneFile)]
    }
    resultProc.running = true
  }

  function runAction(action) {
    var command = String(action || "")
    if (!command) return

    Util.execDetached(command)
  }

  function rowHeightForDetail(detail) {
    return detail ? root.detailRowHeight : root.baseRowHeight
  }

  // Height a dmenu card can devote to rows before running off the screen —
  // or past the frozen top edge once a search has pinned the card in place.
  // Uses panel.cardTop rather than effectiveCardTop: the centered top is
  // derived from the card height, which this value feeds.
  function availableRowsHeight() {
    var top = panel.cardTop >= 0 ? panel.cardTop : Style.gapsOut
    var available = panel.height - top - Style.gapsOut - root.headerHeight - 1 - root.listInset * 2
    // The starting list sets the ceiling along with the offset: filtering
    // never grows the card past where it opened.
    if (panel.maxRowsHeight >= 0) available = Math.min(available, panel.maxRowsHeight)
    // A card that swallows the whole screen reads as a page, not a menu.
    return Math.min(available, Math.round(panel.height * 0.7))
  }

  // When every row fits, the list gets its full height. When they don't,
  // the card must end mid-row: a clipped row is what tells the eye there is
  // more below the fold, so never come out even on a row boundary.
  function foldedListHeight(totals, available) {
    var count = totals.length
    if (count === 0) return root.baseRowHeight
    if (totals[count - 1] <= available) return totals[count - 1]

    var peek = root.rowPeek
    var full = 0
    while (full < count && totals[full] <= available) full++
    while (full > 1 && totals[full - 1] + root.rowSpacing + peek > available) full--
    if (full < 1) return Math.max(available, root.baseRowHeight)

    return totals[full - 1] + root.rowSpacing + peek
  }

  function dmenuRowListHeight(_serial, _count, _filter) {
    if (root.mode === "input") return 0
    if (displayModel.count === 0) return root.baseRowHeight

    var available = availableRowsHeight()
    if (root.dmenuMaxHeight > 0) available = Math.min(available, Style.space(root.dmenuMaxHeight))

    var totals = []
    var total = 0
    for (var i = 0; i < displayModel.count; i++) {
      if (i > 0) total += root.rowSpacing
      total += root.rowHeightForDetail(displayModel.get(i).detail)
      totals.push(total)
    }

    return foldedListHeight(totals, available)
  }

  function item(id) {
    return root.items[id] || null
  }

  // ------------------------------------------------------------------
  // JSONC → normalized item array. Mirrors the bash bin's jq pipeline so
  // the on-disk authoring format stays untouched.
  // ------------------------------------------------------------------

  function stripJsonc(raw) {
    return MenuModel.stripJsonc(raw)
  }

  function normalizeAliases(value) {
    return MenuModel.normalizeAliases(value)
  }

  function normalizeItem(id, raw) {
    return MenuModel.normalizeItem(id, raw)
  }

  function parseMenuJsonc(raw) {
    return MenuModel.parseMenuJsonc(raw)
  }

  function rebuildItemsFromSources() {
    var mergedMenu = MenuModel.mergeMenuSources(root.defaultMenuItems, [])
    root.appsLoaded = false
    root.items = mergedMenu.items
    root.itemOrder = mergedMenu.itemOrder
    root.rowsLoaded = true
    root.evaluateGuards()
    if (root.opened) {
      root.rebuildDisplay()
      if (!root.dmenuActive && (root.activeMenu === "root" || root.activeMenu === "apps")) root.loadApps()
    }
  }

  // The apps provider is QML-native: rows come from the shared AppLibrary
  // (DesktopEntries) instead of a bash enumeration, so they carry image
  // icons and launch feedback.
  function mergeAppRows() {
    if (!root.appLibrary) return

    var rows = root.appLibrary.sortedEntries("")
    var appRows = []
    for (var j = 0; j < rows.length; j++) {
      var entry = rows[j].entry
      var appId = String(entry.id || "")
      if (!appId) continue
      var subtext = root.appLibrary.entrySubtext(entry)
      var aliases = subtext ? [subtext] : []
      try {
        if (entry.keywords && typeof entry.keywords.join === "function") aliases = aliases.concat(entry.keywords)
      } catch (e) { }
      appRows.push({
        id: "apps." + appId,
        parent: "apps",
        kind: "app",
        icon: "",
        appIcon: String(entry.icon || ""),
        appId: appId,
        label: root.appLibrary.entryName(entry),
        title: "",
        target: "",
        description: subtext,
        action: "",
        provider: "",
        aliases: aliases,
        when: "",
        checked: "",
        order: 0
      })
    }

    var merged = MenuModel.mergeAppRows(root.items, root.itemOrder, appRows)
    root.items = merged.items
    root.itemOrder = merged.itemOrder
    if (root.opened) root.rebuildDisplay()
  }

  function loadApps() {
    if (root.appsLoaded || !root.item("apps") || !root.appLibrary) return
    root.appsLoaded = true
    root.mergeAppRows()
  }

  function depthFor(id) {
    return MenuModel.depthFor(root.items, id)
  }

  function pathFor(id) {
    return MenuModel.pathFor(root.items, id)
  }

  function parentPathFor(id) {
    return MenuModel.parentPathFor(root.items, id)
  }

  function isDescendantOf(id, ancestorId) {
    return MenuModel.isDescendantOf(root.items, id, ancestorId)
  }

  function childCount(id) {
    return MenuModel.childCount(root.items, root.itemOrder, id)
  }

  // Guarded items are hidden when their `when:` evaluates false. Static
  // submenus are also hidden when none of their descendants are visible;
  // provider-backed menus stay visible because their rows load on demand.
  function isVisible(entry) {
    return MenuModel.isVisible(root.items, root.itemOrder, root.whenResults, entry)
  }

  // Label with the ✓ marker baked in when `checked:` evaluated truthy.
  function labelFor(entry) {
    return MenuModel.labelFor(entry, root.checkedResults)
  }

  function searchableToken(value) {
    return MenuModel.searchableToken(value)
  }

  function leafIdFor(id) {
    return MenuModel.leafIdFor(id)
  }

  function nameSearchText(entry) {
    return MenuModel.nameSearchText(entry)
  }

  function termInSearchWords(term, text) {
    return MenuModel.termInSearchWords(term, text)
  }

  function descriptionTextMatches(query, text) {
    return MenuModel.descriptionTextMatches(query, text)
  }

  function matchesQuery(entry, query) {
    return MenuModel.matchesQuery(root.items, entry, query,
      MenuModel.isSearchVisible(root.items, root.itemOrder, root.whenResults, entry))
  }

  function searchScore(entry, query) {
    return MenuModel.searchScore(root.items, entry, query)
  }

  function displayRow(entry, detail, score, section) {
    return MenuModel.displayRow(root.items, root.itemOrder, root.checkedResults, entry, detail, score, section)
  }

  function rebuildDmenuDisplay() {
    displayModel.clear()

    if (root.mode === "input") {
      layoutSerial += 1
      return
    }

    var query = root.filterText.trim().toLowerCase()
    for (var i = 0; i < root.dmenuOptions.length; i++) {
      // An option is "<label>", "<glyph>\t<label>", or
      // "<glyph>\t<label>\t<subtext>". The glyph never comes back with the
      // selection; the subtext renders under the label, filters alongside it,
      // and returns with the selection as a stable key for same-named rows.
      var parts = String(root.dmenuOptions[i] || "").split("\t")
      var icon = parts.length > 1 ? parts.shift() : ""
      var label = parts.shift() || ""
      var detail = parts.join("\t")
      if (query && label.toLowerCase().indexOf(query) < 0
          && detail.toLowerCase().indexOf(query) < 0) continue
      displayModel.append({
        itemId: "dmenu." + i,
        kind: "dmenu",
        icon: icon,
        iconFont: "",
        appIcon: "",
        appId: "",
        label: label,
        target: "",
        detail: detail,
        path: "",
        childCount: 0,
        action: "",
        provider: "",
        score: i,
        section: ""
      })
    }

    layoutSerial += 1

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0

    Qt.callLater(function() {
      if (displayModel.count > 0) root.revealCursor()
    })
  }

  function rebuildDisplay() {
    if (root.dmenuActive) {
      root.rebuildDmenuDisplay()
      return
    }

    displayModel.clear()

    if (!root.rowsLoaded) return

    var active = root.item(root.activeMenu) ? root.activeMenu : "root"
    root.activeMenu = active
    var rows = []
    var query = root.filterText.trim()

    if (query) {
      for (var i = 0; i < root.itemOrder.length; i++) {
        var entry = root.item(root.itemOrder[i])
        if (!entry || entry.id === "root") continue
        if (!root.isDescendantOf(entry.id, active)) continue
        if (!root.matchesQuery(entry, query)) continue

        var detail = root.parentPathFor(entry.id)
        rows.push(root.displayRow(entry, detail, root.searchScore(entry, query)))
      }

      rows.sort(function(a, b) {
        if (a.score !== b.score) return a.score - b.score
        return a.path.localeCompare(b.path)
      })
    } else {
      for (var j = 0; j < root.itemOrder.length; j++) {
        var child = root.item(root.itemOrder[j])
        if (!child || (active === "root" ? child.kind !== "app" : child.parent !== active)) continue
        if (!root.isVisible(child)) continue
        rows.push(root.displayRow(child, child.description, child.order))
      }

      // DesktopEntries can reorder its values when an application starts.
      // Keep the palette and Apps route alphabetical independently of provider refreshes.
      if (active === "root" || active === "apps") {
        rows.sort(function(a, b) {
          var aLabel = String(a.label || "").toLowerCase()
          var bLabel = String(b.label || "").toLowerCase()
          if (aLabel < bLabel) return -1
          if (aLabel > bLabel) return 1
          var aId = String(a.itemId || "")
          var bId = String(b.itemId || "")
          if (aId < bId) return -1
          if (aId > bId) return 1
          return 0
        })
      }
      if (active === "root") {
        for (var app = 0; app < rows.length; app++) rows[app].section = "Applications"
        // Direct actions follow the app list; typing searches both together.
        for (var a = 0; a < root.itemOrder.length; a++) {
          var action = root.item(root.itemOrder[a])
          if (action && action.kind === "action" && root.isVisible(action))
            rows.push(root.displayRow(action, root.parentPathFor(action.id), action.order, "Actions"))
        }
      }
    }

    for (var k = 0; k < rows.length; k++) displayModel.append(rows[k])
    layoutSerial += 1

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0

    Qt.callLater(function() {
      if (displayModel.count > 0) root.revealCursor()
    })
  }

  // Contain alone parks the cursor row flush with the viewport edge, hiding
  // the neighbor entirely and losing the fold affordance. Keep the next
  // hidden row peeking past the cursor in the direction of travel.
  function revealCursor() {
    if (displayModel.count === 0) return
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)

    var item = resultList.itemAtIndex(root.selectedIndex)
    if (!item) return

    var reach = root.rowPeek + root.rowSpacing
    if (root.selectedIndex < displayModel.count - 1) {
      var maxY = Math.max(resultList.originY, resultList.originY + resultList.contentHeight - resultList.height)
      var overhang = item.y + item.height + reach - (resultList.contentY + resultList.height)
      if (overhang > 0) resultList.contentY = Math.min(resultList.contentY + overhang, maxY)
    }
    if (root.selectedIndex > 0) {
      var underhang = resultList.contentY - (item.y - reach)
      if (underhang > 0) resultList.contentY = Math.max(resultList.contentY - underhang, resultList.originY)
    }
  }

  function select(delta) {
    if (displayModel.count === 0) return

    root.disarmPointer()
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    revealCursor()
  }

  function setFilter(nextFilter) {
    panel.freezeCardTop()
    root.filterText = nextFilter
    root.selectedIndex = 0
    root.cursorActive = root.mode !== "input"
    root.disarmPointer()
    if (!root.dmenuActive && (root.activeMenu === "root" || root.activeMenu === "apps")) root.loadApps()
    root.rebuildDisplay()
  }

  function setActiveMenu(id, pushHistory, fromPointer) {
    panel.freezeCardTop()
    if (!root.item(id)) id = "root"
    if (pushHistory && id !== root.activeMenu) root.navStack = root.navStack.concat([root.activeMenu])
    root.activeMenu = id
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    if (fromPointer) pointerGate.allowInitialSample()
    else root.disarmPointer()
    root.rebuildDisplay()
    if (id === "root" || id === "apps") root.loadApps()
  }

  function goBack() {
    if (root.activeMenu === "root") return false

    if (root.navStack.length > 0) {
      var previous = root.navStack[root.navStack.length - 1]
      root.navStack = root.navStack.slice(0, root.navStack.length - 1)
      root.setActiveMenu(previous, false)
      return true
    }

    var active = root.item(root.activeMenu)
    root.setActiveMenu((active && active.parent) ? active.parent : "root", false)
    return true
  }

  function activateIndex(index, fromPointer) {
    if (root.dmenuActive) {
      if (root.mode === "input") {
        root.applyDmenuSelection(root.filterText)
        return
      }
      if (index < 0 || index >= displayModel.count) return
      var picked = displayModel.get(index)
      root.applyDmenuSelection(picked.detail ? picked.label + "\t" + picked.detail : picked.label)
      return
    }

    if (index < 0 || index >= displayModel.count) return

    var row = displayModel.get(index)
    if (row.kind === "menu" || row.kind === "link") {
      root.setActiveMenu(row.target || row.itemId, true, fromPointer)
    } else if (row.kind === "app") {
      var appId = row.appId
      var label = row.label
      applySerial = requestSerial
      opened = false
      filterText = ""
      if (root.appLibrary) root.appLibrary.launch(appId, label)
    } else {
      root.applySelected(row.itemId, row.action)
    }
  }

  function applyDmenuSelection(value) {
    applySerial = requestSerial
    opened = false
    filterText = ""
    root.finishRequest(value)
  }

  function applySelected(id, action) {
    if (!id) { cancel(); return }

    applySerial = requestSerial
    opened = false
    filterText = ""
    root.runAction(action)
  }

  function cancel() {
    if (root.dmenuActive) root.finishRequest(null)
    opened = false
    filterText = ""
  }

  function openExistingMenu(initialMenu) {
    requestSerial += 1
    mode = "menu"
    requestActive = false
    selectionFile = ""
    doneFile = ""
    activeMenu = root.item(initialMenu) ? initialMenu : "root"
    navStack = []
    filterText = ""
    selectedIndex = 0
    cursorActive = true
    root.disarmPointer()
    root.evaluateGuards()
    opened = true
    rebuildDisplay()
    if (activeMenu === "root" || activeMenu === "apps") loadApps()
    // The shell may start before first-install packages have finished placing
    // their icons. Refresh here even when the desktop entry list did not change.
    if (root.appLibrary) root.appLibrary.refreshIcons()

    Qt.callLater(function() { searchField.forceActiveFocus() })
  }

  function openDmenu(payload) {
    requestSerial += 1
    panel.unfreezeCardTop()
    mode = payload.mode === "input" ? "input" : "select"
    dmenuPrompt = String(payload.prompt || (mode === "input" ? "Input" : "Select"))
    dmenuOptions = Array.isArray(payload.options) ? payload.options : []
    selectionFile = String(payload.selectionFile || "")
    doneFile = String(payload.doneFile || "")
    requestActive = !!doneFile
    dmenuWidth = Math.max(1, Number(payload.width || 300))
    dmenuMaxHeight = Math.max(0, Number(payload.maxHeight || 0))
    activeMenu = "root"
    navStack = []
    filterText = ""
    selectedIndex = 0
    cursorActive = mode !== "input"
    root.disarmPointer()
    opened = true
    rebuildDisplay()

    Qt.callLater(function() { searchField.forceActiveFocus() })
  }
  ListModel { id: displayModel }

  // ----------------------------------------------------------- route surface
  //
  // The menu is opened through the standard plugin lifecycle:
  // `hrndz-shell ipc shell summon omarchy.menu '{"menu":"system"}'`.
  // Callers may pass a real id (`system`, `setup.audio`) or an alias declared
  // in JSONC (`power`, `capture`). Unknown strings fall through to the
  // id-as-route behavior so misspellings still attempt to open the literal id.
  function resolveRoute(input) {
    return MenuModel.resolveRoute(root.items, root.itemOrder, input)
  }

  function openRoute(initialMenu) {
    var id = root.resolveRoute(initialMenu)
    var entry = root.items[id]
    // If the resolved id is an action (i.e. the user invoked an alias for
    // a leaf), run it directly
    // instead of opening an action with no children.
    if (entry && entry.kind === "action" && entry.action) {
      root.cancel()
      root.runAction(entry.action)
      return "ok"
    }
    // If it's a link (a redirect to another menu), follow the link.
    if (entry && entry.kind === "link" && entry.target) id = entry.target
    root.pendingInitialMenu = id
    root.openExistingMenu(id)
    return "ok"
  }

  function disarmPointer() {
    pointerGate.reset()
  }

  function selectFromPointer(index, item, mouse) {
    if (!pointerGate.moved(item, mouse)) return
    root.cursorActive = true
    root.selectedIndex = index
  }

  Process {
    id: resultProc
    onExited: {
      if (root.applySerial === root.requestSerial)
        root.opened = false
    }
  }

  PointerMoveGate {
    id: pointerGate
    referenceItem: card
  }

  Connections {
    target: root.appLibrary
    function onAppsChanged() {
      if (root.appsLoaded) root.mergeAppRows()
    }
  }

  // menu.jsonc sits in the Nix store, so there is nothing to watch. Before
  // omarchyPath arrives the path would be "/menu.jsonc", whose watch on the
  // parent "" made QFileSystemWatcher warn.
  FileView {
    id: defaultMenuFile
    path: root.omarchyPath ? root.defaultMenuPath : ""
    printErrors: false
    onLoaded: { root.defaultMenuItems = root.parseMenuJsonc(text()); root.rebuildItemsFromSources() }
  }

  // ---------------------------------------------------------------- guards
  //
  // `when:` (visibility) and `checked:` (✓ marker) are bash expressions the
  // shell wasn't allowed to evaluate before the perf rewrite. Now the shell
  // batches them into one bash subprocess per (re)load so the open path
  // never has to wait on them.

  property var whenResults: ({})       // id → true|false (allow visibility)
  property var checkedResults: ({})    // id → true|false (show ✓)
  property bool guardsPending: false

  function evaluateGuards() {
    // Process ignores a command change while it is running, and `collected`
    // belongs to the run in flight, so a second evaluation cannot overwrite
    // the first: it would throw away the lines already read and never start.
    // The surviving tail then lands as the whole answer, and every id lost
    // with it goes back to showing, since a `when:` only hides on an explicit
    // false. Wait for the run in flight and evaluate once it lands instead.
    if (guardProc.running) {
      root.guardsPending = true
      return
    }
    root.guardsPending = false

    var script = MenuModel.guardScript(root.items)
    if (!script) {
      root.whenResults = ({})
      root.checkedResults = ({})
      return
    }
    guardProc.collected = ""
    guardProc.command = ["bash", "-lc", script]
    guardProc.running = true
  }

  Process {
    id: guardProc
    property string collected: ""
    stdout: SplitParser {
      onRead: function(data) { guardProc.collected += data + "\n" }
    }
    onExited: function(exitCode, exitStatus) {
      // A batch that was killed rather than finished has only told us about
      // the rows it reached, and a row whose `when:` went unanswered shows.
      // Keep the last complete set rather than let a half-read one through.
      // A signal leaves the exit code at 0, so the status is what tells us.
      if (exitCode !== 0 || exitStatus !== 0) {
        if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
        return
      }

      var nextWhen = ({})
      var nextChecked = ({})
      var lines = guardProc.collected.split("\n")
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var colon = line.lastIndexOf(":")
        if (colon < 0) continue
        var value = line.substring(colon + 1) === "1"
        var rest = line.substring(0, colon)
        var tagAt = rest.lastIndexOf(":")
        if (tagAt < 0) continue
        var id = rest.substring(0, tagAt)
        var tag = rest.substring(tagAt + 1)
        if (tag === "w") nextWhen[id] = value
        else if (tag === "c") nextChecked[id] = value
      }
      root.whenResults = nextWhen
      root.checkedResults = nextChecked
      if (root.opened) root.rebuildDisplay()
      // Run the evaluation that had to stand aside. Deferred by a turn so the
      // process is settled before its command is set again.
      if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
    }
  }
  PanelWindow {
    id: panel
    visible: root.opened && root.rowsLoaded
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // The palette card is sized by the output and never moves. A dmenu card
    // is sized by its rows: it opens centered, and the first search keystroke
    // freezes the top line where it sits — from then on the card grows and
    // shrinks downward instead of re-centering on every resize, which made
    // it jump around. The rows height is frozen at the same moment, so the
    // starting list also caps how tall the card may grow. Closing or a new
    // request unfreezes both.
    property int cardTop: -1
    property int maxRowsHeight: -1
    readonly property int centeredTop: Math.max(Style.gapsOut, Math.round((height - root.dmenuCardHeight) / 2))
    readonly property int effectiveCardTop: cardTop >= 0 ? cardTop : centeredTop
    function freezeCardTop() {
      if (root.dmenuActive && visible && cardTop < 0) {
        cardTop = effectiveCardTop
        maxRowsHeight = root.visibleRowsHeight
      }
    }
    function unfreezeCardTop() { cardTop = -1; maxRowsHeight = -1 }
    onVisibleChanged: if (!visible) unfreezeCardTop()

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    BorderSurface {
      id: card
      readonly property var rect: root.paletteRect(panel.width, panel.height, root.shell ? root.shell.bar : null)
      x: root.dmenuActive ? Math.round((panel.width - width) / 2) : rect.x
      y: root.dmenuActive ? panel.effectiveCardTop : rect.y
      width: root.dmenuActive ? root.dmenuCardWidth : rect.width
      height: root.dmenuActive ? Math.min(root.dmenuCardHeight, panel.height - Style.gapsOut - panel.effectiveCardTop) : rect.height
      radius: root.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      clip: true

      MouseArea { anchors.fill: parent; onClicked: {} }

      // Header: a drawn magnifier (no icon-font dependency), the field, esc.
      Item {
        id: header
        x: card.borderLeft + Style.space(20)
        y: card.borderTop
        width: parent.width - card.borderLeft - card.borderRight - Style.space(40)
        height: root.headerHeight

        Item {
          id: glyph
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(22)
          height: width
          Rectangle { x: 1; y: 1; width: Style.space(15); height: width; radius: width / 2; color: "transparent"; border.color: root.accent; border.width: 1.8 }
          Rectangle { x: Style.space(13); y: Style.space(13); width: Style.space(9); height: 1.8; radius: 0.9; rotation: 45; transformOrigin: Item.Left; color: root.accent }
        }

        TextField {
          id: searchField
          anchors.left: glyph.right
          anchors.leftMargin: Style.space(4)
          anchors.right: escCap.left
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          background: null
          foreground: root.foreground
          accent: root.accent
          placeholderTextColor: Util.alpha(root.foreground, 0.42)
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          placeholderText: root.dmenuActive ? root.dmenuPrompt + "…"
            : root.activeMenu === "root" ? "What would you like to do?"
            : "Search " + (root.item(root.activeMenu) ? root.item(root.activeMenu).label.toLowerCase() : "") + "…"
          onTextEdited: root.setFilter(text)

          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              if (root.filterText) root.setFilter("")
              else root.cancel()
              event.accepted = true
            } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && !root.filterText) {
              root.goBack()
              event.accepted = true
            } else if (event.key === Qt.Key_Up) {
              root.select(-1)
              event.accepted = true
            } else if (event.key === Qt.Key_Down) {
              root.select(1)
              event.accepted = true
            } else if (event.key === Qt.Key_PageUp) {
              root.select(-6)
              event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
              root.select(6)
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (root.dmenuActive) {
                if (root.mode === "input") root.applyDmenuSelection(root.filterText)
                else if (displayModel.count > 0) root.activateIndex(root.cursorActive ? root.selectedIndex : 0)
              } else if (root.cursorActive) root.activateIndex(root.selectedIndex)
              else if (displayModel.count > 0) root.cursorActive = true
              event.accepted = true
            } else if (event.key === Qt.Key_U && event.modifiers === Qt.ControlModifier) {
              root.setFilter("")
              event.accepted = true
            }
          }
        }

        Keycap {
          id: escCap
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          label: "esc"
          foreground: root.foreground
        }
      }

      Rectangle {
        visible: !(root.dmenuActive && root.mode === "input")
        x: card.borderLeft
        y: header.y + header.height
        width: parent.width - card.borderLeft - card.borderRight
        height: 1
        color: root.hairline
      }

      // Breadcrumb: where the palette is and what the field will search.
      Row {
        id: crumbs
        visible: !root.dmenuActive
        x: card.borderLeft + Style.space(22)
        y: header.y + header.height + Style.space(6)
        height: root.crumbHeight
        spacing: Style.space(10)

        Text {
          id: brand
          anchors.verticalCenter: parent.verticalCenter
          text: "HRNDZ"
          textFormat: Text.PlainText
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 2
          font.weight: Font.Bold
        }
        Text {
          anchors.baseline: brand.baseline
          text: root.activeMenu !== "root" && !root.filterText ? "›" : "/"
          textFormat: Text.PlainText
          color: Util.alpha(root.foreground, 0.35)
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          anchors.baseline: brand.baseline
          width: Math.max(0, card.width - crumbs.x * 2 - brand.width - Style.space(30))
          text: root.crumbText
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }

      Item {
        id: content
        x: card.borderLeft + Style.space(12)
        y: root.dmenuActive ? header.y + header.height + 1 + root.listInset : crumbs.y + crumbs.height + Style.space(4)
        width: parent.width - card.borderLeft - card.borderRight - Style.space(24)
        height: root.dmenuActive ? root.visibleRowsHeight : footer.y - 1 - root.listInset - y
        visible: !(root.dmenuActive && root.mode === "input")

        ListView {
          id: resultList
          anchors.fill: parent
          model: displayModel
          clip: true
          spacing: root.rowSpacing
          boundsBehavior: Flickable.StopAtBounds

          section.property: "section"
          section.criteria: ViewSection.FullString
          section.delegate: Item {
            required property string section

            width: ListView.view.width
            height: section ? root.dividerHeight : 0
            visible: !!section

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(14)
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(2)
              text: section
              textFormat: Text.PlainText
              color: Util.alpha(root.foreground, 0.5)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.weight: Font.Medium
              font.letterSpacing: 0.5
            }
          }

          // Layout adapted from olafkfreund/nixarchy-menu ui/ResultRow.qml
          // (MIT), rev 2cce175c6ffd4747dc42f571760071dc2650282f.
          delegate: BorderSurface {
            id: row
            required property int index
            required property string itemId
            required property string kind
            required property string icon
            required property string iconFont
            required property string appIcon
            required property string appId
            required property string label
            required property string target
            required property string detail
            required property string path
            required property string action
            required property int childCount

            readonly property bool hasCursor: root.cursorActive && row.index === root.selectedIndex
            readonly property bool isApp: row.kind === "app"
            readonly property bool leadsSomewhere: row.kind === "menu" || row.kind === "link"
            readonly property color textColor: row.hasCursor ? root.selectedText : root.foreground

            width: ListView.view.width
            height: root.rowHeightForDetail(row.detail)
            radius: root.cornerRadius
            color: row.hasCursor ? root.selectedBackground : "transparent"
            borderSpec: row.hasCursor ? root.selectedBorderSpec : Border.none()

            Rectangle {
              id: iconChip
              x: root.rowReservedBorderLeft + Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(30)
              height: width
              radius: Math.min(root.cornerRadius, Style.space(7))
              visible: row.icon.length > 0 || row.isApp
              color: row.isApp && appIconImage.status === Image.Ready ? "transparent" : Util.alpha(root.foreground, 0.07)

              Text {
                anchors.centerIn: parent
                visible: !row.isApp || appIconImage.status !== Image.Ready
                text: row.isApp ? row.label.charAt(0).toUpperCase() : row.icon
                textFormat: Text.PlainText
                color: Util.alpha(row.textColor, 0.85)
                font.family: row.iconFont.length > 0 ? row.iconFont : root.fontFamily
                font.pixelSize: Style.font.iconLarge
              }

              Image {
                id: appIconImage
                anchors.fill: parent
                anchors.margins: Style.space(2)
                visible: row.isApp && status === Image.Ready
                fillMode: Image.PreserveAspectFit
                // Decode at physical pixels — a logical-size decode leaves
                // PNG icons upscaled and blurry on HiDPI displays.
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                source: row.isApp && root.appLibrary ? root.appLibrary.iconSource(row.appIcon) : ""
                asynchronous: true
              }
            }

            Column {
              anchors.left: iconChip.visible ? iconChip.right : parent.left
              anchors.leftMargin: iconChip.visible ? Style.space(12) : root.rowReservedBorderLeft + Style.space(14)
              anchors.right: trail.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                width: parent.width
                text: row.label
                textFormat: Text.PlainText
                color: row.textColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.weight: row.hasCursor ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                visible: row.detail.length > 0
                text: row.detail
                textFormat: Text.PlainText
                color: Util.alpha(row.textColor, row.hasCursor ? 0.72 : 0.55)
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            // A submenu shows where it leads; the cursor row shows what ↵ does.
            Text {
              id: trail
              anchors.right: parent.right
              anchors.rightMargin: root.rowReservedBorderRight + Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              text: row.leadsSomewhere ? "›" : row.hasCursor ? "↵" : ""
              textFormat: Text.PlainText
              color: Util.alpha(row.textColor, row.hasCursor ? 0.7 : 0.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.selectFromPointer(row.index, row, {
                x: mouseArea.mouseX,
                y: mouseArea.mouseY
              })
              onPositionChanged: function(mouse) {
                root.selectFromPointer(row.index, row, mouse)
              }
              onClicked: {
                root.cursorActive = true
                root.selectedIndex = row.index
                root.activateIndex(row.index, true)
              }
            }
          }
        }

        // Scroll scrims. The clipped row already marks the fold at rest;
        // these keep both edges honest once the list has been scrolled,
        // when content hides above the card top as well as below. Strength
        // tracks the distance still hidden past each edge rather than
        // animating on a clock, so a programmatic jump — wrapping from the
        // last row back to the first — lands with the fade already applied.
        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: Math.min(Style.space(28), parent.height / 2)
          visible: opacity > 0
          opacity: resultList.contentHeight > resultList.height
            ? Math.max(0, Math.min(1, (resultList.contentY - resultList.originY) / height))
            : 0
          gradient: Gradient {
            GradientStop { position: 0; color: root.background }
            GradientStop { position: 1; color: Util.alpha(root.background, 0) }
          }
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Math.min(Style.space(28), parent.height / 2)
          visible: opacity > 0
          opacity: resultList.contentHeight > resultList.height
            ? Math.max(0, Math.min(1, (resultList.originY + resultList.contentHeight - resultList.height - resultList.contentY) / height))
            : 0
          gradient: Gradient {
            GradientStop { position: 0; color: Util.alpha(root.background, 0) }
            GradientStop { position: 1; color: root.background }
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: Style.space(8)
          visible: displayModel.count === 0 && root.mode !== "input"

          Text {
            text: "󰈉"
            color: root.accent
            opacity: 0.8
            font.family: root.fontFamily
            font.pixelSize: Style.font.displayLarge
            horizontalAlignment: Text.AlignHCenter
            width: Style.space(320)
          }

          Text {
            textFormat: Text.PlainText
            text: root.filterText ? "No matches for “" + root.filterText + "”" : "Nothing here yet"
            color: root.foreground
            opacity: 0.7
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            horizontalAlignment: Text.AlignHCenter
            width: Style.space(320)
          }
        }
      }

      // Footer: the cursor row's place in the menu, and the keys that act.
      Rectangle {
        visible: !root.dmenuActive
        x: card.borderLeft
        y: footer.y - 1
        width: parent.width - card.borderLeft - card.borderRight
        height: 1
        color: root.hairline
      }

      Item {
        id: footer
        visible: !root.dmenuActive
        x: card.borderLeft + Style.space(22)
        y: card.height - card.borderBottom - root.footerHeight
        width: card.width - card.borderLeft - card.borderRight - Style.space(44)
        height: root.footerHeight

        Text {
          anchors.left: parent.left
          anchors.right: keys.left
          anchors.rightMargin: Style.space(16)
          anchors.verticalCenter: parent.verticalCenter
          text: root.currentRow ? (root.currentRow.kind === "app" ? "Applications" : root.currentRow.path) : ""
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Row {
          id: keys
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(16)

          Row {
            visible: root.activeMenu !== "root" && !root.filterText
            spacing: Style.space(8)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Back"
              textFormat: Text.PlainText
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            Keycap { label: "⌫"; foreground: root.foreground }
          }

          Row {
            visible: root.currentVerb.length > 0
            spacing: Style.space(8)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.currentVerb
              textFormat: Text.PlainText
              color: Util.alpha(root.foreground, 0.8)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            Keycap { label: "↵"; bright: true; foreground: root.foreground }
          }
        }
      }
    }
  }

  // Adapted from olafkfreund/nixarchy-menu ui/Keycap.qml (MIT), rev
  // 2cce175c6ffd4747dc42f571760071dc2650282f.
  component Keycap: Rectangle {
    id: keycap
    property string label: ""
    property bool bright: false
    property color foreground: Color.menu.text
    implicitWidth: Math.max(implicitHeight, keyText.implicitWidth + Style.space(12))
    implicitHeight: Style.space(22)
    radius: Math.min(Style.cornerRadius, Style.space(5))
    color: Util.alpha(keycap.foreground, keycap.bright ? 0.14 : 0.07)
    border.width: 1
    border.color: Util.alpha(keycap.foreground, keycap.bright ? 0.28 : 0.14)

    Text {
      id: keyText
      anchors.centerIn: parent
      text: keycap.label
      textFormat: Text.PlainText
      color: Util.alpha(keycap.foreground, keycap.bright ? 0.95 : 0.6)
      font.family: Style.font.menuFamily
      font.pixelSize: Style.font.caption
    }
  }
}
