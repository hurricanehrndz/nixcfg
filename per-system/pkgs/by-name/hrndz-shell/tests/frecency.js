// Frecency reorders equal search matches by use, and never lifts a weaker
// match over a better one.
const assert = require("assert")
const fs = require("fs")
const path = require("path")
const Frecency = require("../shell/plugins/menu/Frecency.js")
const MenuModel = require("../shell/plugins/menu/MenuModel.js")

const day = 86400
const now = 100 * day

// Two apps that both start with "f" (same tier) and one that only contains it.
const menu = MenuModel.mergeMenuSources(MenuModel.parseMenuJsonc(fs.readFileSync(path.join(__dirname, "../menu.jsonc"), "utf8")), [])
const app = (id, label) => ({ id: "apps." + id, parent: "apps", kind: "app", icon: "", appIcon: "", appId: id, label,
  title: "", target: "", description: "", action: "", provider: "", aliases: [], order: 0 })
const { items } = MenuModel.mergeAppRows(menu.items, menu.itemOrder,
  [app("files", "Files"), app("firefox", "Firefox"), app("gimp", "Gimp Refine")])
const rank = (usage, query, ids) => ids
  .map((id) => ({ id, score: MenuModel.searchScore(items, items[id], query) - Frecency.bonus(usage, id, now) }))
  .sort((a, b) => a.score - b.score).map((r) => r.id)

let usage = {}
assert.deepStrictEqual(rank(usage, "f", ["apps.files", "apps.firefox"]), ["apps.files", "apps.firefox"])
usage = Frecency.record(usage, "apps.firefox", now)
assert.deepStrictEqual(rank(usage, "f", ["apps.files", "apps.firefox"]), ["apps.firefox", "apps.files"])

// However heavily used, a contains-match stays below a prefix match.
for (let i = 0; i < 1000; i++) usage = Frecency.record(usage, "apps.gimp", now)
assert.ok(Frecency.bonus(usage, "apps.gimp", now) < 1000)
assert.deepStrictEqual(rank(usage, "fi", ["apps.gimp", "apps.files"]), ["apps.files", "apps.gimp"])

// Use fades: a pick two weeks old counts half.
usage = Frecency.record({}, "apps.files", now)
assert.strictEqual(Frecency.weight(usage, "apps.files", now + 14 * day), 0.5)

// The file stays bounded, keeping the most used.
usage = {}
for (let i = 0; i <= Frecency.MAX_ENTRIES; i++) usage = Frecency.record(usage, "apps.a" + i, now + i)
assert.strictEqual(Object.keys(usage).length, Frecency.MAX_ENTRIES)
assert.ok(!("apps.a0" in usage))

// A damaged or foreign file reads as no history rather than breaking search.
assert.deepStrictEqual(Frecency.parse("not json"), {})
assert.deepStrictEqual(Frecency.parse(JSON.stringify({ version: 2, entries: { x: { weight: 1, updated: 0 } } })), {})
assert.deepStrictEqual(Object.keys(Frecency.parse(JSON.stringify({ version: 1, entries: {
  ok: { weight: 1, updated: 0 }, bad: { weight: "x" }, huge: { weight: 1e9, updated: 0 } } }))), ["ok"])
assert.deepStrictEqual(Frecency.parse(Frecency.serialize(usage)), usage)

console.log("frecency: ok")
