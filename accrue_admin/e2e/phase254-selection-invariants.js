"use strict";

// Phase 254 CIQ-02 (D-14): the selection-report invariants, shared by the Node selector
// (scripts/ci/phase254_selection.mjs, an ES module) and the Playwright lane
// (phase253-composition-helpers.js). They live in a side-effect-free CommonJS module because
// Playwright's own module loader cannot require() an ES module, and a second copy of the
// invariants could drift from the selector that writes the report.

const crypto = require("node:crypto");

const REPORT_KIND = "phase254-selection";
const MODES = Object.freeze(["full", "affected"]);

class SelectionError extends Error {}

function fail(message, code = "SELECTION_FAILED") {
  const error = new SelectionError(`Phase 254 selection: ${message}`);
  error.code = code;
  throw error;
}

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function isObject(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

const byCodeUnit = (left, right) => (left < right ? -1 : left > right ? 1 : 0);

function sortedUnique(values) {
  return [...new Set(values)].sort(byCodeUnit);
}

function exactSet(actual, expected, label) {
  const left = [...actual].sort(byCodeUnit);
  const right = [...expected].sort(byCodeUnit);
  if (left.length !== new Set(left).size || right.length !== new Set(right).size || JSON.stringify(left) !== JSON.stringify(right)) {
    fail(`${label} mismatch; expected ${new Set(right).size} unique ids and received ${left.length}`, "SELECTION_INVARIANT");
  }
}

function sentinelsDigest(sentinels) {
  return sha256(JSON.stringify([...sentinels].sort(byCodeUnit)));
}

function assertSelectionInvariants(report) {
  if (!isObject(report) || report.kind !== REPORT_KIND) fail("not a selection report", "SELECTION_INVARIANT");
  if (!MODES.includes(report.mode)) fail(`unsupported selection mode ${JSON.stringify(report.mode)}`, "SELECTION_INVARIANT");
  for (const key of ["total_ids", "selected", "excluded", "sentinels", "mode_reasons"]) {
    if (!Array.isArray(report[key])) fail(`report lacks ${key}`, "SELECTION_INVARIANT");
  }
  const total = report.total_ids;
  if (JSON.stringify(total) !== JSON.stringify(sortedUnique(total)) || total.length === 0) fail("total_ids must be a non-empty sorted unique list", "SELECTION_INVARIANT");
  const selectedIds = report.selected.map((item) => item.id);
  const excludedIds = report.excluded.map((item) => item.id);
  if (new Set(selectedIds).size !== selectedIds.length) fail("selected contains a duplicate id", "SELECTION_INVARIANT");
  if (new Set(excludedIds).size !== excludedIds.length) fail("excluded contains a duplicate id", "SELECTION_INVARIANT");
  const overlap = selectedIds.filter((id) => excludedIds.includes(id));
  if (overlap.length > 0) fail(`selected and excluded overlap: ${overlap.slice(0, 5).join(", ")}`, "SELECTION_INVARIANT");
  exactSet([...selectedIds, ...excludedIds], total, "selected plus excluded versus total_ids");
  const stale = report.sentinels.filter((id) => !total.includes(id));
  if (stale.length > 0) fail(`stale sentinel ids are not in total_ids: ${stale.join(", ")}`, "SELECTION_INVARIANT");
  const missing = report.sentinels.filter((id) => !selectedIds.includes(id));
  if (missing.length > 0) fail(`selected omits sentinels: ${missing.join(", ")}`, "SELECTION_INVARIANT");
  if (report.sentinels_sha256 !== sentinelsDigest(report.sentinels)) fail("sentinels_sha256 does not match the sentinel set", "SELECTION_INVARIANT");
  if (report.selected.some((item) => !Array.isArray(item.reasons) || item.reasons.length === 0)) fail("a selected case has no reason", "SELECTION_INVARIANT");
  if (report.excluded.some((item) => typeof item.reason !== "string" || item.reason === "")) fail("an excluded case has no reason", "SELECTION_INVARIANT");
  if (report.mode === "full" && (report.excluded.length > 0 || report.mode_reasons.length === 0)) fail("full mode must select every case and name its reason", "SELECTION_INVARIANT");
  if (report.counts && (report.counts.total !== total.length || report.counts.selected !== selectedIds.length || report.counts.excluded !== excludedIds.length)) {
    fail("report counts disagree with the id lists", "SELECTION_INVARIANT");
  }
  return true;
}

module.exports = {
  MODES,
  REPORT_KIND,
  SelectionError,
  assertSelectionInvariants,
  fail,
  sentinelsDigest,
};
