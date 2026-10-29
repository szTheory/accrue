// The committed visual baseline set guard (Phase 211, upgraded by Phase 254 CIQ-03 / D-18).
//
// Two independent sources describe the set, and the guard compares BOTH against a third that nothing
// in the directory can influence:
//
//   expected set   the twelve legacy Phase 211 names (a literal list in this file) plus the case keys of
//                  the tracked accrue_admin/storybook/phase254-visual-cases.json (only the selection
//                  projector writes it and its --check drift-verifies it against the compiled manifests)
//   PNG files      what is actually committed in the baseline directory
//   manifest.json  the identity manifest: one entry per PNG key with its sha256 and provenance
//
// The manifest is never the source of the expected set, so deleting a PNG together with its manifest
// entry is still a failure. A guard that only checks the manifest against itself proves nothing.
//
// CLI: node visual-baseline-set.cjs <baseline-directory> [--pre-mint]
// --pre-mint is for local use before the first CI mint only: it tolerates a missing PNG whose key is
// listed in phase254-visual-cases.json and has no manifest entry yet. Every other rule still applies,
// and no workflow may pass it.

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const EXPECTED_BASELINES = Object.freeze([
  "dashboard.png",
  "dashboard-dark.png",
  "subscriptions.png",
  "subscriptions-dark.png",
  "subscription-detail.png",
  "subscription-detail-dark.png",
  "component-kitchen.png",
  "component-kitchen-dark.png",
  "invoices.png",
  "invoices-dark.png",
  "invoice-detail.png",
  "invoice-detail-dark.png"
]);

const MANIFEST_FILE = "manifest.json";
const CASES_PATH = path.join(__dirname, "..", "storybook", "phase254-visual-cases.json");
const PROVENANCE_LEGACY = "phase211-committed";
const PROVENANCE_MINT = "phase254-mint";
const HEX64 = /^[0-9a-f]{64}$/;
const HEX40 = /^[0-9a-f]{40}$/;

// Playwright derives the snapshot file name from the toHaveScreenshot name with its own
// sanitizeForFilePath: every run of control characters, punctuation and symbols (underscore
// included) becomes one hyphen. A case key such as phase254-page-scheduled_cancellation-w320-light
// is therefore stored as phase254-page-scheduled-cancellation-w320-light.png.
function snapshotFileName(key) {
  return `${key.replace(/[\x00-\x2C\x2E-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F]+/g, "-")}.png`;
}

function readCaseKeys(casesPath = CASES_PATH) {
  const parsed = JSON.parse(fs.readFileSync(casesPath, "utf8"));
  if (!Array.isArray(parsed.cases) || parsed.cases.length === 0) throw new Error(`${casesPath} lists no cases`);
  return parsed.cases.map((item) => item.key);
}

// The independent expected set as {key, file, legacy}: the legacy names (key = the name without its
// extension) plus one entry per case key (file = the sanitized snapshot name).
function expectedBaselines(caseKeys) {
  const rows = [
    ...EXPECTED_BASELINES.map((file) => ({ key: file.replace(/\.png$/, ""), file, legacy: true })),
    ...caseKeys.map((key) => ({ key, file: snapshotFileName(key), legacy: false })),
  ];
  if (new Set(rows.map((row) => row.file)).size !== rows.length || new Set(rows.map((row) => row.key)).size !== rows.length) {
    throw new Error("the expected baseline set has duplicate keys or file names");
  }
  return rows;
}

function expectedBaselineNames(caseKeys) {
  return expectedBaselines(caseKeys).map((row) => row.file);
}

function sha256File(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function isObject(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

// Required fields of one manifest entry (D-18). Legacy entries leave the mint and served fields null; a
// minted entry may not.
function validateEntry(key, entry) {
  const errors = [];
  if (!isObject(entry)) return [`${key}: the manifest entry is not an object`];
  if (!HEX64.test(entry.sha256 ?? "")) errors.push(`${key}: sha256 is missing or not 64 hex characters`);
  if (entry.case_key !== key) errors.push(`${key}: case_key must equal the manifest key`);
  if (entry.file !== undefined && entry.file !== snapshotFileName(key)) errors.push(`${key}: file must be the sanitized snapshot name ${snapshotFileName(key)}`);
  if (![PROVENANCE_LEGACY, PROVENANCE_MINT].includes(entry.provenance)) errors.push(`${key}: provenance must be ${PROVENANCE_LEGACY} or ${PROVENANCE_MINT}`);
  if (typeof entry.reason !== "string" || entry.reason.trim() === "") errors.push(`${key}: reason is missing`);
  if (!("finding_id" in entry)) errors.push(`${key}: finding_id is missing`);
  if (entry.provenance === PROVENANCE_LEGACY) {
    if (!HEX40.test(entry.last_commit ?? "")) errors.push(`${key}: a legacy entry records the commit that last changed the PNG`);
    if (entry.mint_run_id !== null) errors.push(`${key}: a legacy entry has no mint run id`);
  }
  if (entry.provenance === PROVENANCE_MINT) {
    if (typeof entry.mint_run_id !== "string" || entry.mint_run_id === "") errors.push(`${key}: mint_run_id is missing`);
    if (!HEX40.test(entry.mint_sha ?? "")) errors.push(`${key}: mint_sha is missing or not a commit sha`);
    if (typeof entry.finding_id !== "string" || entry.finding_id === "") errors.push(`${key}: finding_id is missing for a minted entry`);
    if (!["story", "mounted"].includes(entry.kind)) errors.push(`${key}: kind must be story or mounted`);
    const served = entry.served;
    for (const field of ["css_sha256", "js_sha256", "geist_sans_sha256", "geist_mono_sha256"]) {
      if (!isObject(served) || !HEX64.test(served[field] ?? "")) errors.push(`${key}: served.${field} is missing`);
    }
    if (!HEX64.test(entry.scenario_file_sha256 ?? "")) errors.push(`${key}: scenario_file_sha256 is missing`);
    if (typeof entry.playwright_version !== "string" || entry.playwright_version === "") errors.push(`${key}: playwright_version is missing`);
    if (typeof entry.browser_version !== "string" || entry.browser_version === "") errors.push(`${key}: browser_version is missing`);
  }
  return errors;
}

function listPngFiles(directory) {
  try {
    return fs.readdirSync(directory, { withFileTypes: true })
      .filter((entry) => entry.isFile() && entry.name.endsWith(".png"))
      .map((entry) => entry.name)
      .sort();
  } catch {
    return [];
  }
}

function listOtherFiles(directory) {
  try {
    return fs.readdirSync(directory, { withFileTypes: true })
      .filter((entry) => !(entry.isFile() && entry.name.endsWith(".png")) && entry.name !== MANIFEST_FILE)
      .map((entry) => entry.name)
      .sort();
  } catch {
    return [];
  }
}

function readManifest(directory) {
  const file = path.join(directory, MANIFEST_FILE);
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    return { manifest: null, error: `${MANIFEST_FILE} is missing or not valid JSON (${error.code || error.message})` };
  }
  if (!isObject(parsed) || parsed.schema_version !== 1 || !isObject(parsed.entries)) {
    return { manifest: null, error: `${MANIFEST_FILE} must be {schema_version: 1, entries: {...}}` };
  }
  return { manifest: parsed, error: null };
}

// Compares the PNG set and the manifest key set against the independent expected set.
function checkBaselineSet(directory, { preMint = false, caseKeys, casesPath } = {}) {
  const keys = caseKeys ?? readCaseKeys(casesPath);
  const rows = expectedBaselines(keys);
  const expected = rows.map((row) => row.file);
  const expectedKeys = new Set(rows.map((row) => row.key));
  const present = new Set(listPngFiles(directory));
  const { manifest, error: manifestError } = readManifest(directory);
  const entries = manifest ? manifest.entries : {};

  const missing = [];
  const preMintTolerated = [];
  for (const row of rows) {
    if (present.has(row.file)) continue;
    if (preMint && !row.legacy && !(row.key in entries)) preMintTolerated.push(row.file);
    else missing.push(row.file);
  }
  const extra = [...present].filter((name) => !expected.includes(name));
  const otherFiles = listOtherFiles(directory);

  const mismatched = [];
  const fieldErrors = [];
  const manifestMissing = [];
  const manifestExtra = [];
  if (manifest) {
    for (const row of rows) {
      if (row.key in entries) continue;
      // A PNG without its entry is never tolerated; only the pre-mint absence of both is.
      const tolerated = preMint && !row.legacy && !present.has(row.file);
      if (!tolerated) manifestMissing.push(row.key);
    }
    for (const key of Object.keys(entries)) if (!expectedKeys.has(key)) manifestExtra.push(key);
    for (const row of rows) {
      const entry = entries[row.key];
      if (entry === undefined) continue;
      fieldErrors.push(...validateEntry(row.key, entry));
      if (present.has(row.file) && HEX64.test(entry?.sha256 ?? "") && sha256File(path.join(directory, row.file)) !== entry.sha256) mismatched.push(row.file);
    }
  }

  const problems = [];
  if (manifestError) problems.push(manifestError);
  if (missing.length) problems.push(`missing PNGs (${missing.length}): ${missing.join(", ")}`);
  if (extra.length) problems.push(`PNGs outside the expected set (${extra.length}): ${extra.join(", ")}`);
  if (otherFiles.length) problems.push(`unexpected non-PNG files (${otherFiles.length}): ${otherFiles.join(", ")}`);
  if (manifestMissing.length) problems.push(`expected keys without a manifest entry (${manifestMissing.length}): ${manifestMissing.join(", ")}`);
  if (manifestExtra.length) problems.push(`manifest entries outside the expected set (${manifestExtra.length}): ${manifestExtra.join(", ")}`);
  if (mismatched.length) problems.push(`PNG bytes differ from the manifest sha256 (${mismatched.length}): ${mismatched.join(", ")}`);
  if (fieldErrors.length) problems.push(`manifest field errors (${fieldErrors.length}):\n${fieldErrors.map((line) => `  ${line}`).join("\n")}`);

  return {
    expected,
    missing,
    preMintTolerated,
    extra,
    otherFiles,
    mismatched,
    fieldErrors,
    manifestMissing,
    manifestExtra,
    manifestError,
    problems,
    ok: problems.length === 0,
  };
}

function main(argv) {
  const flags = argv.filter((token) => token.startsWith("--"));
  const positional = argv.filter((token) => !token.startsWith("--"));
  const unknown = flags.filter((flag) => flag !== "--pre-mint");
  const directory = positional[0];
  if (!directory || unknown.length > 0 || positional.length > 1) {
    console.error("Usage: node visual-baseline-set.cjs <baseline-directory> [--pre-mint]");
    return 2;
  }
  const preMint = flags.includes("--pre-mint");
  const result = checkBaselineSet(directory, { preMint });
  if (!result.ok) {
    console.error(`Visual baseline set check failed${preMint ? " (--pre-mint)" : ""}:\n${result.problems.map((line) => `- ${line}`).join("\n")}`);
    return 1;
  }
  const tolerated = result.preMintTolerated.length;
  console.log(
    `Found all ${result.expected.length - tolerated} required visual baselines in ${directory} (${result.expected.length} expected, manifest and bytes verified)` +
      (tolerated ? `; ${tolerated} case baselines are not minted yet (--pre-mint)` : ".")
  );
  return 0;
}

if (require.main === module) {
  process.exitCode = main(process.argv.slice(2));
}

module.exports = {
  EXPECTED_BASELINES,
  MANIFEST_FILE,
  PROVENANCE_LEGACY,
  PROVENANCE_MINT,
  checkBaselineSet,
  expectedBaselineNames,
  expectedBaselines,
  readCaseKeys,
  snapshotFileName,
  validateEntry,
};
