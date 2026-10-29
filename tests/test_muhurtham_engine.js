const fs = require("fs");
const path = require("path");
const vm = require("vm");

console.log("=================================================================");
console.log("  BharatAstrologyMuhurtham Automated Headless Verification Suite  ");
console.log("=================================================================");

const htmlPath = path.resolve(__dirname, "..", "index.html");
if (!fs.existsSync(htmlPath)) {
  console.error("FAIL: index.html not found at " + htmlPath);
  process.exit(1);
}

const html = fs.readFileSync(htmlPath, "utf8");

// Mock browser DOM environment for VM execution
const mockElements = new Map();
const createMockElement = (id = "") => ({
  id,
  style: {},
  classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild() {},
  removeChild() {},
  addEventListener() {},
  removeEventListener() {},
  setAttribute() {},
  getAttribute() { return null; },
  textContent: "",
  value: "",
  disabled: false
});

const sandbox = {
  console,
  Math,
  Date,
  Array,
  Object,
  String,
  Number,
  Boolean,
  RegExp,
  JSON,
  parseInt,
  parseFloat,
  isNaN,
  isFinite,
  setTimeout: () => 1,
  clearTimeout: () => {},
  setInterval: () => 1,
  clearInterval: () => {},
  navigator: { onLine: true, userAgent: "Node-Headless-Audit" },
  location: { href: "http://localhost/" },
  localStorage: {
    _data: {},
    getItem(k) { return this._data[k] || null; },
    setItem(k, v) { this._data[k] = String(v); },
    removeItem(k) { delete this._data[k]; },
    clear() { this._data = {}; }
  },
  document: {
    getElementById(id) {
      if (!mockElements.has(id)) mockElements.set(id, createMockElement(id));
      return mockElements.get(id);
    },
    querySelector(sel) {
      return createMockElement(sel);
    },
    querySelectorAll() { return []; },
    createElement(tag) { return createMockElement(tag); },
    addEventListener() {},
    removeEventListener() {},
    body: createMockElement("body"),
    documentElement: createMockElement("html")
  },
  window: {}
};
sandbox.window = sandbox;
sandbox.global = sandbox;

// Extract JS from index.html
const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
if (!scriptMatch) {
  console.error("FAIL: Could not locate <script> block in index.html");
  process.exit(1);
}

const scriptCode = scriptMatch[1];
const context = vm.createContext(sandbox);

try {
  vm.runInContext(scriptCode, context, { filename: "index.html-inline.js" });
  console.log("[OK] Inline Jyotish script parsed & executed successfully in headless sandbox.\n");
} catch (err) {
  console.error("FAIL: Script execution error in headless VM:", err);
  process.exit(1);
}

// Retrieve lexical constants from VM context
const lexGlobals = vm.runInContext(`({
  RASHI_NAMES, RASHI_NAMES_ML,
  NAKSHATRA_NAMES, NAKSHATRA_NAMES_ML,
  KOLLAM_MONTHS, KOLLAM_MONTHS_ML,
  TARA_NAMES, TARA_NAMES_ML,
  SWISSEPH_CONFIG
})`, context);

// Test Runner Helper
let passedTests = 0;
let failedTests = 0;

function assert(condition, testName, details = "") {
  if (condition) {
    console.log(`  [PASS] ${testName}`);
    passedTests++;
  } else {
    console.error(`  [FAIL] ${testName} ${details ? "(" + details + ")" : ""}`);
    failedTests++;
  }
}

function assertClose(actual, expected, tolerance, testName) {
  const diff = Math.abs(actual - expected);
  assert(diff <= tolerance, testName, `Expected ~${expected}, got ${actual}, diff ${diff.toFixed(6)} > ${tolerance}`);
}

console.log("--- Suite 1: Astronomical & Mathematical Calculation Engine ---");

// Test 1: Julian Date benchmark
// 2000-01-01 12:00 UTC (tz=0) -> JD 2451545.0
const jd2000 = sandbox.getJulianDate(2000, 1, 1, 12, 0, 0);
assertClose(jd2000, 2451545.0, 0.0001, "getJulianDate J2000.0 Epoch benchmark (2451545.0)");

// Test 2: Julian Date Unix Epoch
// 1970-01-01 00:00 UTC -> JD 2440587.5
const jdUnix = sandbox.getJulianDate(1970, 1, 1, 0, 0, 0);
assertClose(jdUnix, 2440587.5, 0.0001, "getJulianDate Unix Epoch benchmark (2440587.5)");

// Test 3: Lahiri Ayanamsha benchmark at J2000.0
const ayan2000 = sandbox.getLahiriAyanamsha(2451545.0);
assertClose(ayan2000, 23.858072, 0.001, "getLahiriAyanamsha at J2000.0 (23.858072 deg)");

// Test 4: Lahiri Ayanamsha rate in 2026 (~24.22 deg)
const jd2026 = sandbox.getJulianDate(2026, 1, 1, 0, 0, 0);
const ayan2026 = sandbox.getLahiriAyanamsha(jd2026);
assert(ayan2026 > 24.20 && ayan2026 < 24.30, "getLahiriAyanamsha in 2026 is between 24.20 and 24.30 deg", `Got: ${ayan2026.toFixed(4)}`);

// Test 5: Sun Longitude sanity
const sunLong = sandbox.getSunLongitude(jd2026);
assert(sunLong >= 0 && sunLong < 360, "getSunLongitude within [0, 360) deg range", `Got: ${sunLong.toFixed(2)}`);

// Test 6: Moon Longitude sanity
const moonLong = sandbox.getMoonLongitude(jd2026);
assert(moonLong >= 0 && moonLong < 360, "getMoonLongitude within [0, 360) deg range", `Got: ${moonLong.toFixed(2)}`);

// Test 7: Moon motion sanity over 24 hours
const jdNextDay = sandbox.getJulianDate(2026, 1, 2, 0, 0, 0);
const moonLongNext = sandbox.getMoonLongitude(jdNextDay);
let moonDelta = (moonLongNext - moonLong + 360) % 360;
assert(moonDelta >= 10.5 && moonDelta <= 15.5, "Moon diurnal motion between 10.5 and 15.5 deg/day", `Delta: ${moonDelta.toFixed(2)} deg`);

// Test 8: Planetary Positions (all 9 grahas)
const planets = sandbox.getPlanetaryPositions(jd2026, ayan2026);
const expectedPlanets = ["sun", "moon", "mars", "mercury", "jupiter", "venus", "saturn", "rahu", "ketu"];
expectedPlanets.forEach(p => {
  assert(typeof planets[p] === "number" && !isNaN(planets[p]), `Planetary coordinate calculated for ${p}`, `Value: ${planets[p]}`);
  assert(planets[p] >= 0 && planets[p] < 360, `${p} within [0, 360) deg range`);
});

// Test 9: Rahu - Ketu exact 180-degree opposition
const rahuKetuDiff = Math.abs((planets.ketu - planets.rahu + 360) % 360);
assertClose(rahuKetuDiff, 180.0, 0.001, "Rahu-Ketu exact 180-degree axis opposition");

// Test 10: Ascendant (Lagna) calculation
const lagna = sandbox.getAscendant(jd2026, 8.5241, 76.9366, ayan2026);
assert(typeof lagna === "object" && lagna !== null, "getAscendant returns lagna structure");
assert(lagna.longitude >= 0 && lagna.longitude < 360, "Ascendant longitude within [0, 360) deg", `Lagna: ${lagna.longitude.toFixed(2)}`);
assert(lagna.rashiIdx >= 0 && lagna.rashiIdx < 12, "Ascendant rashi index within 0..11", `Rashi: ${lagna.rashiIdx}`);
assert(lagna.degInRashi >= 0 && lagna.degInRashi < 30, "Ascendant degree in rashi within 0..30", `Deg: ${lagna.degInRashi.toFixed(2)}`);

// Test 11: KP Sub Lord calculation
if (typeof sandbox.getKPSubLord === "function") {
  const kpSub = sandbox.getKPSubLord(120.5, 3);
  assert(typeof kpSub === "object" && kpSub !== null, "getKPSubLord returns valid KP structure");
}

console.log("\n--- Suite 2: Kerala Jyotish & Electional Rules Validation ---");

// Test 12: Constants integrity
assert(Array.isArray(lexGlobals.RASHI_NAMES) && lexGlobals.RASHI_NAMES.length === 12, "12 Classical Rashi names defined");
assert(Array.isArray(lexGlobals.NAKSHATRA_NAMES) && lexGlobals.NAKSHATRA_NAMES.length === 27, "27 Nakshatra names defined");
assert(Array.isArray(lexGlobals.KOLLAM_MONTHS) && lexGlobals.KOLLAM_MONTHS.length === 12, "12 Kollam solar months defined");
assert(Array.isArray(lexGlobals.TARA_NAMES) && lexGlobals.TARA_NAMES.length === 9, "9 Navatara names defined");

// Test 13: Malayalam localization mirrors English matrices 1:1
assert(lexGlobals.RASHI_NAMES_ML.length === 12, "12 Malayalam Rashi names defined");
assert(lexGlobals.NAKSHATRA_NAMES_ML.length === 27, "27 Malayalam Nakshatra names defined");
assert(lexGlobals.KOLLAM_MONTHS_ML.length === 12, "12 Malayalam Kollam months defined");
assert(lexGlobals.TARA_NAMES_ML.length === 9, "9 Malayalam Navatara names defined");

// Test 14: Swiss Ephemeris configuration
assert(lexGlobals.SWISSEPH_CONFIG.license === "GNU AGPL-3.0 (Astrodienst AG)", "Astrodienst Swiss Ephemeris license metadata verified");

console.log("\n--- Suite 3: Security & Code Hygiene Standards ---");

// Test 15: Zero-innerHTML enforcement
const innerHTMLOccurrences = (html.match(/\.innerHTML\b/g) || []).length;
assert(innerHTMLOccurrences === 0, "Zero-innerHTML security guarantee strictly observed (0 occurrences)", `Found: ${innerHTMLOccurrences}`);

// Test 16: Zero-eval & Zero-Function constructor check
const evalOccurrences = (html.match(/\beval\s*\(/g) || []).length;
const newFunctionOccurrences = (html.match(/new\s+Function\s*\(/g) || []).length;
assert(evalOccurrences === 0 && newFunctionOccurrences === 0, "Zero dynamic code execution (no eval, no new Function)", `eval: ${evalOccurrences}, new Function: ${newFunctionOccurrences}`);

// Test 17: No document.write
const docWriteOccurrences = (html.match(/document\.write\s*\(/g) || []).length;
assert(docWriteOccurrences === 0, "Zero document.write calls in markup or scripts", `Found: ${docWriteOccurrences}`);

console.log("\n=======================================================");
console.log(`Test Execution Finished: ${passedTests} PASSED, ${failedTests} FAILED`);
console.log("=======================================================");

if (failedTests > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
