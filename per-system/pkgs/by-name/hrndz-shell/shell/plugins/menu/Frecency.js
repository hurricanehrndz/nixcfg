// Frecency: what gets picked often and lately ranks first among equal search
// matches. Each item keeps a weight that decays by half every two weeks and
// gains one per pick. Pure functions over a plain { id: { weight, updated } }
// object; the menu owns the file (~/.local/state/hrndz-shell/menu-usage.json).
// Times are seconds since the epoch.
//
// Adapted from olafkfreund/nixarchy-menu core/Frecency.js (MIT), rev
// 2cce175c6ffd4747dc42f571760071dc2650282f, without its per-query learning:
// the ids here are app and menu ids, not search text, so they stay plain.

var HALF_LIFE = 14 * 86400
var MAX_ENTRIES = 500
// Search scores come in tiers 1000 apart (MenuModel.searchScore). Staying
// under that means use reorders equal matches but never lifts a weak match
// over a better one.
var MAX_BONUS = 900

function parse(text) {
  var entries = {}
  try {
    var data = JSON.parse(String(text || ""))
    if (!data || data.version !== 1 || typeof data.entries !== "object") return entries
    for (var id in data.entries) {
      var e = data.entries[id]
      var w = Number(e && e.weight), u = Number(e && e.updated)
      if (!id || !isFinite(w) || !isFinite(u) || w < 0 || w > 1e6) continue
      entries[id] = { weight: w, updated: u }
    }
  } catch (err) { }
  return entries
}

function serialize(entries) {
  return JSON.stringify({ version: 1, entries: entries }) + "\n"
}

function weight(entries, id, now) {
  var e = entries[id]
  if (!e) return 0
  return e.weight * Math.pow(2, -Math.max(0, now - e.updated) / HALF_LIFE)
}

// Subtracted from a search score (lower sorts first). One recent pick is
// worth 300; it saturates around seven.
function bonus(entries, id, now) {
  return Math.min(MAX_BONUS, Math.round(300 * Math.log2(1 + weight(entries, id, now))))
}

// A new entries object with one more pick of `id`; the weakest are dropped
// past MAX_ENTRIES so the file stays small however many apps come and go.
function record(entries, id, now) {
  var next = {}
  for (var existing in entries) next[existing] = entries[existing]
  next[id] = { weight: Math.min(1e6, weight(entries, id, now) + 1), updated: now }
  var ids = Object.keys(next)
  if (ids.length > MAX_ENTRIES) {
    ids.sort(function(a, b) { return weight(next, b, now) - weight(next, a, now) })
    var pruned = {}
    for (var i = 0; i < MAX_ENTRIES; i++) pruned[ids[i]] = next[ids[i]]
    next = pruned
  }
  return next
}

if (typeof module !== "undefined") {
  module.exports = { parse: parse, serialize: serialize, weight: weight, bonus: bonus, record: record, MAX_ENTRIES: MAX_ENTRIES }
}
