const assert = require("node:assert/strict")
const test = require("node:test")
const Menu = require("../shell/plugins/menu/MenuModel.js")

const source = Menu.parseMenuJsonc(JSON.stringify({
  system: { label: "System", when: "feature-on" },
  "system.shutdown": { label: "Shutdown", action: "systemctl poweroff" },
  setup: { label: "Setup" },
  "setup.audio": { label: "Volume & audio", aliases: ["sound"], action: "open-audio" }
}))
const menu = Menu.mergeMenuSources(source, [])

test("palette searches actions through their breadcrumb and aliases", () => {
  const shutdown = menu.items["system.shutdown"]
  const audio = menu.items["setup.audio"]
  assert.equal(Menu.matchesQuery(menu.items, shutdown, "sysshut", true), true)
  assert.equal(Menu.matchesQuery(menu.items, shutdown, "system shut", true), true)
  assert.equal(Menu.matchesQuery(menu.items, audio, "sound", true), true)
  assert.equal(Menu.matchesQuery(menu.items, audio, "bluetooth", true), false)
})

test("palette search hides actions beneath guarded parents", () => {
  const shutdown = menu.items["system.shutdown"]
  assert.equal(Menu.isSearchVisible(menu.items, menu.itemOrder, {}, shutdown), true)
  assert.equal(Menu.isSearchVisible(menu.items, menu.itemOrder, { system: false }, shutdown), false)
})

test("an exact application match outranks a menu action", () => {
  const app = { id: "apps.volume", parent: "apps", kind: "app", label: "Volume", aliases: [], description: "", order: 20 }
  const items = { ...menu.items, apps: { id: "apps", parent: "root", kind: "menu", label: "Apps" }, [app.id]: app }
  assert.ok(Menu.searchScore(items, app, "volume") < Menu.searchScore(items, menu.items["setup.audio"], "volume"))
})
