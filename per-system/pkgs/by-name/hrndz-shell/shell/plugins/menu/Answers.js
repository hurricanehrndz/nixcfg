// Answers: a row computed from the query instead of picked from the tree —
// arithmetic ("128 * 1.24", "15% of 80", "sqrt(2)") and unit or temperature
// conversion ("5 km in mi", "70 f to c"). Pure functions; the menu shows the
// result above the matches and copies it on activate.
//
// Adapted from olafkfreund/nixarchy-menu core/Calculator.js and core/Units.js
// (MIT), rev 2cce175c6ffd4747dc42f571760071dc2650282f. Time zones are left
// out: they need tzdata, which QML's JavaScript engine does not expose.

// ------------------------------------------------------------- calculator
//
// Bounded arithmetic: a hand-written tokenizer and recursive-descent parser.
// Never evaluates user input as code.

var FUNCS = {
  sqrt: Math.sqrt, sin: Math.sin, cos: Math.cos, tan: Math.tan,
  log: function(x) { return Math.log(x) / Math.LN10 }, ln: Math.log,
  abs: Math.abs, round: function(x) { return Math.round(x) },
  ceil: Math.ceil, floor: Math.floor
}
var CONSTS = { pi: Math.PI, e: Math.E, tau: 2 * Math.PI }
var MAX_TOKENS = 90

function CalcError(kind, message) {
  this.kind = kind          // "syntax" for incomplete/malformed, "value" for out of range
  this.message = message
}

function preprocess(text) {
  var t = String(text || "")
  if (t.length > 256) throw new CalcError("value", "Expression too long")
  t = t.trim().replace(/^=+/, "").trim().replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**")
  t = t.replace(/(\d+(?:\.\d+)?)\s*%\s+of\s+/gi, "($1/100)*")
  t = t.replace(/(\d+(?:\.\d+)?)%(?!\s*\d)/g, "($1/100)")
  return t
}

function tokenize(text) {
  var tokens = [], i = 0
  while (i < text.length) {
    var c = text.charAt(i)
    if (c === " " || c === "\t") { i++; continue }
    var m
    if ((m = /^\d+(?:\.\d*)?(?:e[+-]?\d+)?|^\.\d+(?:e[+-]?\d+)?/i.exec(text.slice(i)))) {
      tokens.push({ t: "num", v: parseFloat(m[0]) }); i += m[0].length; continue
    }
    if ((m = /^[a-z_][a-z0-9_]*/i.exec(text.slice(i)))) {
      tokens.push({ t: "id", v: m[0].toLowerCase() }); i += m[0].length; continue
    }
    if (text.substr(i, 2) === "**" || text.substr(i, 2) === "//") { tokens.push({ t: "op", v: text.substr(i, 2) }); i += 2; continue }
    if ("+-*/%()".indexOf(c) >= 0) { tokens.push({ t: "op", v: c }); i++; continue }
    throw new CalcError("syntax", "Unsupported character")
  }
  if (tokens.length > MAX_TOKENS) throw new CalcError("value", "Expression too complex")
  return tokens
}

function check(v) {
  if (typeof v !== "number" || !isFinite(v) || Math.abs(v) > 1e150) throw new CalcError("value", "Result out of range")
  return v
}

function floorMod(a, b) {
  if (b === 0) throw new CalcError("value", "Division by zero")
  return a - b * Math.floor(a / b)
}

function Parser(tokens) { this.tokens = tokens; this.pos = 0 }
Parser.prototype.peek = function() { return this.tokens[this.pos] }
Parser.prototype.next = function() { return this.tokens[this.pos++] }
Parser.prototype.isOp = function(v) { var t = this.peek(); return t && t.t === "op" && t.v === v }
Parser.prototype.expr = function() {
  var v = this.term()
  while (this.isOp("+") || this.isOp("-")) {
    var op = this.next().v, r = this.term()
    v = check(op === "+" ? v + r : v - r)
  }
  return v
}
Parser.prototype.term = function() {
  var v = this.unary()
  while (this.isOp("*") || this.isOp("/") || this.isOp("%") || this.isOp("//")) {
    var op = this.next().v, r = this.unary()
    if (op === "*") v = v * r
    else if (op === "/") { if (r === 0) throw new CalcError("value", "Division by zero"); v = v / r }
    else if (op === "%") v = floorMod(v, r)
    else { if (r === 0) throw new CalcError("value", "Division by zero"); v = Math.floor(v / r) }
    check(v)
  }
  return v
}
Parser.prototype.unary = function() {
  if (this.isOp("+")) { this.next(); return this.unary() }
  if (this.isOp("-")) { this.next(); return check(-this.unary()) }
  return this.power()
}
Parser.prototype.power = function() {
  var base = this.primary()
  if (this.isOp("**")) {
    this.next()
    var exp = this.unary()   // right-associative, like Python
    if (Math.abs(exp) > 1000 || Math.abs(base) > 1e100) throw new CalcError("value", "Exponent too large")
    return check(Math.pow(base, exp))
  }
  return base
}
Parser.prototype.primary = function() {
  var t = this.next()
  if (!t) throw new CalcError("syntax", "Incomplete expression")
  if (t.t === "num") return check(t.v)
  if (t.t === "id") {
    if (CONSTS[t.v] !== undefined && !this.isOp("(")) return CONSTS[t.v]
    if (FUNCS[t.v] && this.isOp("(")) {
      this.next()
      var arg = this.expr()
      if (!this.isOp(")")) throw new CalcError("syntax", "Expected )")
      this.next()
      return check(FUNCS[t.v](arg))
    }
    throw new CalcError("value", "Unsupported expression")
  }
  if (t.t === "op" && t.v === "(") {
    var v = this.expr()
    if (!this.isOp(")")) throw new CalcError("syntax", "Expected )")
    this.next()
    return v
  }
  throw new CalcError("syntax", "Unexpected token")
}

// Python-like %g formatting with `precision` significant digits.
function format(value, precision) {
  var p = Math.max(1, Math.min(21, Number(precision) || 12))
  var n = Number(Number(value).toPrecision(p))
  if (Math.abs(n) >= 1e16 || (n !== 0 && Math.abs(n) < 1e-4)) return n.toExponential(Math.max(0, p - 1)).replace(/\.?0+e/, "e")
  return String(n)
}

// The value of `text` as arithmetic, or null. Only an expression that does
// something counts: a bare number or constant ("5", "e", "pi") is a search
// for an app, not a sum.
function calculate(text) {
  try {
    var tokens = tokenize(preprocess(text))
    var acts = tokens.some(function(t) { return t.t === "op" && t.v !== "(" && t.v !== ")" || t.t === "id" && FUNCS[t.v] })
    if (!acts) return null
    var p = new Parser(tokens)
    var v = p.expr()
    if (p.pos !== tokens.length) return null
    return check(v)
  } catch (e) {
    if (e instanceof CalcError) return null
    throw e
  }
}

// ---------------------------------------------------------------- units

var UNITS = [
  [1, "length", "m meter meters metre metres"], [0.01, "length", "cm centimeter centimeters"],
  [0.001, "length", "mm millimeter millimeters"], [1000, "length", "km kilometer kilometers"],
  [0.3048, "length", "ft foot feet"], [0.0254, "length", "in inch inches"],
  [0.9144, "length", "yd yard yards"], [1609.344, "length", "mi mile miles"],
  [1, "mass", "kg kilogram kilograms"], [0.001, "mass", "g gram grams"],
  [0.45359237, "mass", "lb lbs pound pounds"], [0.028349523125, "mass", "oz ounce ounces"],
  [1, "time", "s sec second seconds"], [60, "time", "min minute minutes"],
  [3600, "time", "h hr hour hours"], [86400, "time", "d day days"],
  [1, "volume", "l liter liters litre litres"], [0.001, "volume", "ml milliliter milliliters"],
  [3.785411784, "volume", "gal gallon gallons"],
  [1, "data", "b byte bytes"], [1000, "data", "kb"], [1e6, "data", "mb"], [1e9, "data", "gb"],
  [1024, "data", "kib"], [1048576, "data", "mib"], [1073741824, "data", "gib"],
  [1, "speed", "m/s"], [1 / 3.6, "speed", "km/h kph"], [0.44704, "speed", "mph"]
]
var LOOKUP = {}
for (var u = 0; u < UNITS.length; u++) {
  var aliases = UNITS[u][2].split(" ")
  for (var a = 0; a < aliases.length; a++) LOOKUP[aliases[a]] = { factor: UNITS[u][0], dimension: UNITS[u][1] }
}
var TEMPERATURES = { c: "c", celsius: "c", f: "f", fahrenheit: "f", k: "k", kelvin: "k" }
var UNIT_RE = /^\s*(-?\d+(?:\.\d+)?)\s*([\w\/°]+)\s+(?:in|to)\s+([\w\/°]+)\s*$/i

// { value, unit, note } for "<number> <unit> in|to <unit>", or null.
function convert(text) {
  var m = UNIT_RE.exec(String(text || ""))
  if (!m) return null
  var value = parseFloat(m[1])
  var source = m[2].toLowerCase().replace(/^°/, ""), target = m[3].toLowerCase().replace(/^°/, "")
  if (TEMPERATURES[source] && TEMPERATURES[target]) {
    source = TEMPERATURES[source]; target = TEMPERATURES[target]
    var celsius = source === "f" ? (value - 32) * 5 / 9 : source === "k" ? value - 273.15 : value
    if (celsius < -273.15) return null
    var out = target === "f" ? celsius * 9 / 5 + 32 : target === "k" ? celsius + 273.15 : celsius
    return { value: out, unit: "°" + target.toUpperCase(), note: "Temperature" }
  }
  var s = LOOKUP[source], t = LOOKUP[target]
  if (!s || !t || s.dimension !== t.dimension) return null
  var note = ["gal", "gallon", "gallons", "kb", "mb", "gb"].indexOf(target) !== -1 || ["gal", "gallon", "gallons", "kb", "mb", "gb"].indexOf(source) !== -1
    ? "US liquid gallons · decimal KB/MB/GB" : "Unit conversion"
  return { value: value * s.factor / t.factor, unit: target, note: note }
}

// ---------------------------------------------------------------- answer

// The answer row for a query, or null: `title` is what shows and `copy` what
// ↵ puts on the clipboard (the bare number, so it pastes into anything).
function answer(query) {
  var q = String(query || "").trim()
  if (!q) return null

  var converted = convert(q)
  if (converted) {
    var number = format(converted.value, 10)
    return { title: number + " " + converted.unit, detail: converted.note + " · " + q, copy: number, icon: "󰑭" }
  }

  var value = calculate(q)
  if (value === null) return null
  var result = format(value, 12)
  return { title: result, detail: "Calculator · " + q.replace(/^=+/, "").trim() + " =", copy: result, icon: "󰃬" }
}

if (typeof module !== "undefined") {
  module.exports = { answer: answer, calculate: calculate, convert: convert, format: format }
}
