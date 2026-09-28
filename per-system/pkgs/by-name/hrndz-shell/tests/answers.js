// The menu's answer row: sums and conversions answer, app searches don't.
const assert = require("assert")
const { answer } = require("../shell/plugins/menu/Answers.js")

const title = (q) => (answer(q) || {}).title
const copy = (q) => (answer(q) || {}).copy

assert.strictEqual(title("128 * 1.24"), "158.72")
assert.strictEqual(title("15% of 80"), "12")
assert.strictEqual(title("2^10"), "1024")
assert.strictEqual(title("sqrt(2)"), "1.41421356237")
assert.strictEqual(title("(1 + 2) * 3"), "9")
assert.strictEqual(title("= 7 // 2"), "3")
assert.strictEqual(title("5 km in mi"), "3.106855961 mi")
assert.strictEqual(title("70 f to c"), "21.11111111 °C")
assert.strictEqual(title("1 gib in mb"), "1073.741824 mb")
// ↵ copies the bare number so it pastes into anything.
assert.strictEqual(copy("5 km in mi"), "3.106855961")

// Searching for an app must not turn into a sum: bare numbers and constants,
// words, unfinished or impossible expressions, and mismatched units.
for (const q of ["", "5", "e", "pi", "firefox", "tan", "1 +", "1 / 0", "5 km in kg", "-500 c to k", "open 2 files"])
  assert.strictEqual(answer(q), null, JSON.stringify(q))

console.log("answers: ok")
