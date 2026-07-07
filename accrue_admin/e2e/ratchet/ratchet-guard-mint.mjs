/**
 * ratchet-guard-mint.mjs — the reusable "guard mint" for the UI ratchet (Phase 207, v1.56).
 *
 * This is the "assert the invariant, not the pixel" half of ORCH-05. When 207-06's `ui.fix`
 * orchestration resolves a finding, it calls `mintGuardRow()` + `appendMintedRow()` here to emit
 * ONE typed DATA row into the correct human-reviewed-once loop test (bootstrapped by 207-03
 * Task 1), never per-finding generated assertion code (D-44). The kind-routing table below is the
 * concrete, deliberate resolution of D-45's dimension → guard-kind mapping.
 *
 * Design invariants:
 *   - Pure + self-test-friendly: `kindForFinding`/`homeSpecForKind` never touch the filesystem;
 *     this module NEVER probes a live page (the 207-06 caller supplies freshly re-captured
 *     `probedFields` per D-44). Zero network, zero LLM, zero Anthropic SDK.
 *   - Never re-derives the guard-token grammar: it imports `GUARD_HOME_SPECS`/`checkGuardRef`/
 *     `isSafeSpecPath` from `phase-ratchet-ledger.mjs` (207-01) so the minted `guard_ref` passes
 *     the SAME deterministic gate that CI enforces — no second, possibly-diverging regex.
 *   - Write-target safety (T-207-02): `targetSpecPath` is ALWAYS derived from the closed
 *     `homeSpecForKind` table and re-validated via the imported `isSafeSpecPath` allowlist before
 *     any write; the write only ever replaces the exact delimited `@ratchet:auto-guards` marker
 *     region, never the rest of the file.
 *   - Idempotent append (T-207-09, D-46): grep-before-append on the exact `@ratchet:<finding_id>`
 *     token — a re-run can never silently duplicate a row; rows stay sorted by `finding_id`.
 *
 * Usage:
 *   node e2e/ratchet/ratchet-guard-mint.mjs --self-test   # pure fixture proof, no real writes
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { GUARD_HOME_SPECS, checkGuardRef, isSafeSpecPath } from "./phase-ratchet-ledger.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// __dirname === accrue_admin/e2e/ratchet/ — go up 3 levels to the repo root (matches
// phase-ratchet-ledger.mjs's REPO_ROOT derivation exactly).
const REPO_ROOT = path.resolve(__dirname, "../../..");

// The EXACT delimiter pair 207-03 Task 1 bootstrapped into each guard-home spec. This module
// greps for these literal strings — the spacing/casing must never diverge.
const OPEN_MARKER = "// >>> @ratchet:auto-guards >>>";
const CLOSE_MARKER = "// <<< @ratchet:auto-guards <<<";

// -----------------------------------------------------------------------------
// Kind routing (D-45) — the closed dimension → guard-kind table. Pure, fs-free.
// -----------------------------------------------------------------------------

/**
 * kindForFinding({dimension, defect_bucket, effort_class}) — routes a finding to its guard kind
 * per the closed D-45 table. `effort_class === "ia-product-decision"` ALWAYS forces
 * `"ledger-count"` regardless of dimension (D-45's explicit override). Any dimension the table
 * does not name falls through to the `"ledger-count"` sentinel.
 */
function kindForFinding({ dimension, defect_bucket, effort_class } = {}) {
  if (effort_class === "ia-product-decision") return "ledger-count";

  switch (dimension) {
    case 1:
      return "design-token";
    case 2:
      return "ledger-count"; // hierarchy / visual-weight
    case 3:
      // density-balance: only the inconsistent-rhythm bucket gets a concrete spacing-scale guard;
      // cramped/wasteful are subjective density calls → ledger-count.
      return defect_bucket === "inconsistent-rhythm" ? "spacing-scale" : "ledger-count";
    case 4:
      return "ledger-count";
    case 5:
      return "ledger-count"; // responsive-composition
    case 6:
      return "contrast";
    case 7:
      return "focus-ring";
    case 8:
      return "ledger-count"; // brand-tier gestalt
    case 9:
      return "motion";
    case 10:
      return "ledger-count";
    case 11:
      return "ledger-count";
    case 12:
      return "microcopy";
    default:
      return "ledger-count";
  }
}

/**
 * homeSpecForKind(kind) — maps a guard kind to its home guard-spec file (a member of the imported
 * `GUARD_HOME_SPECS` allowlist), or `null` for the `"ledger-count"` sentinel (no home file). Pure,
 * fs-free.
 */
function homeSpecForKind(kind) {
  switch (kind) {
    case "design-token":
    case "contrast":
    case "spacing-scale":
      return "accrue_admin/e2e/foundation-tokens.spec.js";
    case "microcopy":
      return "accrue_admin/e2e/admin-page-flow-phase200.spec.js";
    case "focus-ring":
      return "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js";
    case "motion":
      return "accrue_admin/e2e/reduced-motion.spec.js";
    case "ledger-count":
      return null;
    default:
      return null;
  }
}

const REQUIRED_FIELDS_BY_KIND = Object.freeze({
  "design-token": ["selector", "property", "expected_token"],
  contrast: ["selector", "min_ratio"],
  "spacing-scale": ["selector", "property", "allowed_values"],
  microcopy: ["route", "expected_text", "old_text"],
  "focus-ring": ["selector"],
  motion: ["route", "selector", "max_ms"],
});

function requiredFieldsForKind(kind) {
  return REQUIRED_FIELDS_BY_KIND[kind] || [];
}

function isMissingRequiredValue(value) {
  if (value === null || value === undefined) return true;
  if (Array.isArray(value)) return value.length === 0;
  if (typeof value === "string") return value.trim() === "";
  return false;
}

function missingRequiredFields(kind, row) {
  const missing = [];
  if (!row || typeof row !== "object") {
    return ["finding_id", "kind", ...requiredFieldsForKind(kind)];
  }
  if (isMissingRequiredValue(row.finding_id)) missing.push("finding_id");
  if (row.kind !== kind) missing.push("kind");
  for (const field of requiredFieldsForKind(kind)) {
    if (isMissingRequiredValue(row[field])) missing.push(field);
  }
  return missing;
}

function validateConcreteRow(row, targetSpecPath) {
  if (!row || typeof row !== "object") {
    throw new Error("appendMintedRow: malformed concrete guard row (not an object)");
  }
  const kind = row.kind;
  if (!kind || kind === "ledger-count" || requiredFieldsForKind(kind).length === 0) {
    throw new Error(`appendMintedRow: malformed concrete guard row kind ${JSON.stringify(kind)}`);
  }
  const expectedHome = homeSpecForKind(kind);
  if (expectedHome !== targetSpecPath) {
    throw new Error(
      `appendMintedRow: ${kind} row belongs in ${JSON.stringify(expectedHome)}, not ${JSON.stringify(targetSpecPath)}`
    );
  }
  const missing = missingRequiredFields(kind, row);
  if (missing.length > 0) {
    throw new Error(`appendMintedRow: ${kind} row missing required field(s): ${missing.join(", ")}`);
  }
}

// -----------------------------------------------------------------------------
// Per-kind row shapes — EXACTLY the shapes 207-03 Task 1's loop tests read. The `finding_id` +
// `kind` come from the finding; every other field is a freshly re-captured `probedFields` value
// (D-44) supplied by the 207-06 caller — this module never probes a live page itself.
// -----------------------------------------------------------------------------

function buildRow(kind, finding, probedFields = {}) {
  const finding_id = finding.finding_id;
  const p = probedFields || {};
  switch (kind) {
    case "design-token":
      return { finding_id, kind, selector: p.selector, property: p.property, expected_token: p.expected_token };
    case "contrast":
      return { finding_id, kind, selector: p.selector, min_ratio: p.min_ratio };
    case "spacing-scale":
      return { finding_id, kind, selector: p.selector, property: p.property, allowed_values: p.allowed_values };
    case "microcopy":
      return { finding_id, kind, route: p.route, expected_text: p.expected_text, old_text: p.old_text };
    case "focus-ring":
      return { finding_id, kind, selector: p.selector };
    case "motion":
      return { finding_id, kind, route: p.route, selector: p.selector, max_ms: p.max_ms };
    default:
      throw new Error(`buildRow: unroutable kind ${JSON.stringify(kind)}`);
  }
}

/**
 * mintGuardRow(finding, probedFields) — routes a resolved finding to `{ guard_ref, targetSpecPath,
 * row }`. For the `"ledger-count"` sentinel kind it returns `{ guard_ref: "ledger-count",
 * targetSpecPath: null, row: null }` immediately (D-40 — no file touch). Otherwise it derives the
 * home spec, sanity-asserts it against the imported `isSafeSpecPath` allowlist at mint time
 * (T-207-02), builds the greppable `guard_ref` in the EXACT grammar the imported `checkGuardRef`
 * validates, and builds the per-kind row.
 */
function mintGuardRow(finding, probedFields = {}) {
  const kind = kindForFinding(finding);
  if (kind === "ledger-count") {
    return { guard_ref: "ledger-count", targetSpecPath: null, row: null };
  }

  const targetSpecPath = homeSpecForKind(kind);
  // Defense in depth: the derived home path MUST be a member of the imported allowlist before we
  // ever build a guard_ref that will later drive a file write.
  if (!isSafeSpecPath(targetSpecPath) || !GUARD_HOME_SPECS.includes(targetSpecPath)) {
    throw new Error(
      `mintGuardRow: kind ${JSON.stringify(kind)} resolved to a non-allowlisted home spec: ${JSON.stringify(
        targetSpecPath
      )}`
    );
  }

  const guard_ref = `${targetSpecPath}::@ratchet:${finding.finding_id}`;
  const row = buildRow(kind, finding, probedFields);
  const missing = missingRequiredFields(kind, row);
  if (missing.length > 0) {
    return {
      guard_ref: "ledger-count",
      targetSpecPath: null,
      row: null,
      downgraded_from: kind,
      missing_fields: missing,
    };
  }
  return { guard_ref, targetSpecPath, row };
}

// -----------------------------------------------------------------------------
// Marker-region read/rewrite. WE own the serialization format (one JSON row per line, each with a
// trailing `// @ratchet:<finding_id>` token comment), so parsing is a simple, deterministic
// line scan — the token comment is what makes the minted guard greppable by `checkGuardRef` and
// idempotent by grep-before-append.
// -----------------------------------------------------------------------------

/** locateRegion(text) — the `[bodyStart, closeIdx)` byte span between the two marker comments. */
function locateRegion(text) {
  const openIdx = text.indexOf(OPEN_MARKER);
  if (openIdx === -1) throw new Error(`locateRegion: open marker not found (${OPEN_MARKER})`);
  const bodyStart = openIdx + OPEN_MARKER.length;
  const closeIdx = text.indexOf(CLOSE_MARKER, bodyStart);
  if (closeIdx === -1) throw new Error(`locateRegion: close marker not found (${CLOSE_MARKER})`);
  return { bodyStart, closeIdx };
}

/** parseExistingRows(body) — recover the row objects from a serialized declaration body. */
function parseExistingRows(body) {
  const rows = [];
  for (const line of body.split("\n")) {
    const start = line.indexOf("{");
    const end = line.lastIndexOf("}");
    if (start === -1 || end === -1 || end < start) continue; // declaration open/close lines
    rows.push(JSON.parse(line.slice(start, end + 1)));
  }
  return rows;
}

/** serializeDeclaration(rows) — render the `const RATCHET_AUTO_GUARDS = [...]` block. */
function serializeDeclaration(rows) {
  if (rows.length === 0) return "const RATCHET_AUTO_GUARDS = [];";
  const lines = rows.map((r) => `  ${JSON.stringify(r)}, // @ratchet:${r.finding_id}`);
  return `const RATCHET_AUTO_GUARDS = [\n${lines.join("\n")}\n];`;
}

function sortByFindingId(rows) {
  return rows
    .slice()
    .sort((a, b) => (a.finding_id < b.finding_id ? -1 : a.finding_id > b.finding_id ? 1 : 0));
}

/**
 * appendMintedRow(targetSpecPath, row, repoRoot) — idempotently append one minted row into the
 * `@ratchet:auto-guards` marker region of `targetSpecPath`. Idempotent (D-46): if the region
 * already contains the exact `@ratchet:<finding_id>` token it returns unchanged WITHOUT writing,
 * so a second call with the same `finding_id` leaves the file byte-identical. Rows stay sorted
 * ascending by `finding_id`. Only the delimited region text is rewritten — the rest of the file
 * is left byte-identical (T-207-02). Returns `{ changed: boolean }`.
 */
function appendMintedRow(targetSpecPath, row, repoRoot) {
  if (!isSafeSpecPath(targetSpecPath)) {
    throw new Error(`appendMintedRow: refusing unsafe/non-allowlisted spec path: ${JSON.stringify(targetSpecPath)}`);
  }
  validateConcreteRow(row, targetSpecPath);
  const absPath = path.join(repoRoot, targetSpecPath);
  const text = fs.readFileSync(absPath, "utf8");
  const { bodyStart, closeIdx } = locateRegion(text);
  const body = text.slice(bodyStart, closeIdx);

  const token = `@ratchet:${row.finding_id}`;
  if (body.includes(token)) {
    return { changed: false }; // grep-before-append idempotent no-op (D-46)
  }

  const rows = sortByFindingId([...parseExistingRows(body), row]);
  const newBody = `\n${serializeDeclaration(rows)}\n`;
  const newText = text.slice(0, bodyStart) + newBody + text.slice(closeIdx);
  fs.writeFileSync(absPath, newText);
  return { changed: true };
}

// -----------------------------------------------------------------------------
// Self-test (D-44/D-45/D-46) — proves routing, the effort override, idempotent double-append, the
// sorted-row invariant, and a real round-trip through the IMPORTED `checkGuardRef` — all on
// `fs.mkdtempSync` COPIES of the real guard-home specs. NEVER writes a real committed spec file.
// -----------------------------------------------------------------------------

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

/** hex16(seed) — a valid `f-[0-9a-f]{16}` finding_id from a small integer seed. */
function hex16(seed) {
  return `f-${seed.toString(16).padStart(16, "0")}`;
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-guard-mint-"));
  try {
    // (a) kindForFinding — full 12-dimension table + effort override.
    {
      const cases = [
        [{ dimension: 1 }, "design-token"],
        [{ dimension: 2 }, "ledger-count"],
        [{ dimension: 3, defect_bucket: "inconsistent-rhythm" }, "spacing-scale"],
        [{ dimension: 3, defect_bucket: "cramped" }, "ledger-count"],
        [{ dimension: 3, defect_bucket: "wasteful" }, "ledger-count"],
        [{ dimension: 4 }, "ledger-count"],
        [{ dimension: 5 }, "ledger-count"],
        [{ dimension: 6 }, "contrast"],
        [{ dimension: 7 }, "focus-ring"],
        [{ dimension: 8 }, "ledger-count"],
        [{ dimension: 9 }, "motion"],
        [{ dimension: 10 }, "ledger-count"],
        [{ dimension: 11 }, "ledger-count"],
        [{ dimension: 12 }, "microcopy"],
      ];
      for (const [finding, expected] of cases) {
        assertSelfTest(
          `(a) kindForFinding dim=${finding.dimension} bucket=${finding.defect_bucket ?? "-"} -> ${expected}`,
          kindForFinding(finding) === expected,
          kindForFinding(finding)
        );
      }
      // effort_class override forces ledger-count regardless of dimension.
      assertSelfTest(
        "(a) effort override: dim=1 + ia-product-decision -> ledger-count",
        kindForFinding({ dimension: 1, effort_class: "ia-product-decision" }) === "ledger-count"
      );
      assertSelfTest(
        "(a) effort override: dim=6 + ia-product-decision -> ledger-count",
        kindForFinding({ dimension: 6, effort_class: "ia-product-decision" }) === "ledger-count"
      );
    }

    // (a2) homeSpecForKind mapping + the ledger-count sentinel.
    {
      assertSelfTest(
        "(a2) design-token/contrast/spacing-scale -> foundation-tokens home",
        homeSpecForKind("design-token") === "accrue_admin/e2e/foundation-tokens.spec.js" &&
          homeSpecForKind("contrast") === "accrue_admin/e2e/foundation-tokens.spec.js" &&
          homeSpecForKind("spacing-scale") === "accrue_admin/e2e/foundation-tokens.spec.js"
      );
      assertSelfTest(
        "(a2) microcopy/focus-ring/motion -> their homes",
        homeSpecForKind("microcopy") === "accrue_admin/e2e/admin-page-flow-phase200.spec.js" &&
          homeSpecForKind("focus-ring") === "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js" &&
          homeSpecForKind("motion") === "accrue_admin/e2e/reduced-motion.spec.js"
      );
      assertSelfTest("(a2) ledger-count -> null (sentinel, no home)", homeSpecForKind("ledger-count") === null);
      // every non-sentinel home is a member of the imported allowlist.
      for (const kind of ["design-token", "contrast", "spacing-scale", "microcopy", "focus-ring", "motion"]) {
        assertSelfTest(
          `(a2) home for ${kind} is in imported GUARD_HOME_SPECS`,
          GUARD_HOME_SPECS.includes(homeSpecForKind(kind))
        );
      }
    }

    // (b) ledger-count sentinel mint — no file touch, null row + targetSpecPath.
    {
      const out = mintGuardRow({ finding_id: hex16(0xaa), dimension: 2 }, {});
      assertSelfTest(
        "(b) ledger-count sentinel: guard_ref='ledger-count', null targetSpecPath+row",
        out.guard_ref === "ledger-count" && out.targetSpecPath === null && out.row === null,
        JSON.stringify(out)
      );
    }

    // (b2) incomplete concrete rows degrade to the ledger-count sentinel instead of writing
    // structurally incomplete data into committed guard-home specs (CR-02).
    {
      const incompleteCases = [
        {
          name: "design-token",
          finding: { finding_id: hex16(0xb1), dimension: 1 },
          probed: { selector: ".ax-card", property: "color", expected_token: null },
          missing: "expected_token",
        },
        {
          name: "spacing-scale",
          finding: { finding_id: hex16(0xb2), dimension: 3, defect_bucket: "inconsistent-rhythm" },
          probed: { selector: ".ax-card", property: "padding", allowed_values: [] },
          missing: "allowed_values",
        },
        {
          name: "microcopy",
          finding: { finding_id: hex16(0xb3), dimension: 12 },
          probed: { route: "/billing/customers", expected_text: "", old_text: "Empty" },
          missing: "expected_text",
        },
      ];

      for (const { name, finding, probed, missing } of incompleteCases) {
        const out = mintGuardRow(finding, probed);
        assertSelfTest(
          `(b2) incomplete ${name} degrades to ledger-count`,
          out.guard_ref === "ledger-count" &&
            out.targetSpecPath === null &&
            out.row === null &&
            out.downgraded_from === name &&
            out.missing_fields.includes(missing),
          JSON.stringify(out)
        );
      }
    }

    // (c) round-trip every real synth kind through the IMPORTED checkGuardRef, against a mkdtemp
    // COPY of the real target spec (never the real committed file).
    {
      const kindFixtures = [
        {
          kind: "design-token",
          finding: { finding_id: hex16(0x11), dimension: 1 },
          probed: { selector: "[data-ax-foundation-status='info']", property: "color", expected_token: "--ax-status-info" },
        },
        {
          kind: "contrast",
          finding: { finding_id: hex16(0x12), dimension: 6 },
          probed: { selector: "[data-ax-foundation-status='danger']", min_ratio: 4.5 },
        },
        {
          kind: "spacing-scale",
          finding: { finding_id: hex16(0x13), dimension: 3, defect_bucket: "inconsistent-rhythm" },
          probed: { selector: ".ax-card", property: "padding", allowed_values: ["8px", "16px", "24px"] },
        },
        {
          kind: "microcopy",
          finding: { finding_id: hex16(0x14), dimension: 12 },
          probed: { route: "/billing/customers", expected_text: "No customers yet", old_text: "Empty" },
        },
        {
          kind: "focus-ring",
          finding: { finding_id: hex16(0x15), dimension: 7 },
          probed: { selector: ".ax-button" },
        },
        {
          kind: "motion",
          finding: { finding_id: hex16(0x16), dimension: 9 },
          probed: { route: "/billing/dev/components", selector: ".ax-dropdown-panel", max_ms: 1 },
        },
      ];

      for (const { kind, finding, probed } of kindFixtures) {
        const { guard_ref, targetSpecPath, row } = mintGuardRow(finding, probed);
        assertSelfTest(`(c) ${kind}: routed kind matches`, row.kind === kind, `${row.kind}`);

        // Build a fake repo root and copy ONLY the one real target spec into its allowlisted path.
        const fakeRepo = fs.mkdtempSync(path.join(root, `repo-${kind}-`));
        const destAbs = path.join(fakeRepo, targetSpecPath);
        fs.mkdirSync(path.dirname(destAbs), { recursive: true });
        fs.copyFileSync(path.join(REPO_ROOT, targetSpecPath), destAbs);

        const res = appendMintedRow(targetSpecPath, row, fakeRepo);
        assertSelfTest(`(c) ${kind}: append changed the copy`, res.changed === true);

        const check = checkGuardRef(guard_ref, finding.finding_id, fakeRepo);
        assertSelfTest(`(c) ${kind}: minted guard_ref passes imported checkGuardRef`, check.ok === true, JSON.stringify(check));
      }
    }

    // (d) idempotent double-append is byte-identical.
    {
      const targetSpecPath = "accrue_admin/e2e/foundation-tokens.spec.js";
      const fakeRepo = fs.mkdtempSync(path.join(root, "repo-idem-"));
      const destAbs = path.join(fakeRepo, targetSpecPath);
      fs.mkdirSync(path.dirname(destAbs), { recursive: true });
      fs.copyFileSync(path.join(REPO_ROOT, targetSpecPath), destAbs);

      const { row } = mintGuardRow(
        { finding_id: hex16(0x21), dimension: 6 },
        { selector: ".ax-button", min_ratio: 4.5 }
      );
      const first = appendMintedRow(targetSpecPath, row, fakeRepo);
      const afterFirst = fs.readFileSync(destAbs);
      const second = appendMintedRow(targetSpecPath, row, fakeRepo);
      const afterSecond = fs.readFileSync(destAbs);

      assertSelfTest("(d) first append changed the file", first.changed === true);
      assertSelfTest("(d) second append is a no-op (changed=false)", second.changed === false);
      assertSelfTest(
        "(d) file byte-identical after double append",
        Buffer.compare(afterFirst, afterSecond) === 0
      );
    }

    // (d2) direct malformed append is refused before any file rewrite.
    {
      const targetSpecPath = "accrue_admin/e2e/foundation-tokens.spec.js";
      const fakeRepo = fs.mkdtempSync(path.join(root, "repo-malformed-"));
      const destAbs = path.join(fakeRepo, targetSpecPath);
      fs.mkdirSync(path.dirname(destAbs), { recursive: true });
      fs.copyFileSync(path.join(REPO_ROOT, targetSpecPath), destAbs);
      const before = fs.readFileSync(destAbs, "utf8");

      let threw = false;
      try {
        appendMintedRow(
          targetSpecPath,
          { finding_id: hex16(0xd2), kind: "design-token", selector: ".ax-card", property: "color" },
          fakeRepo
        );
      } catch (error) {
        threw = /design-token row missing required field\(s\): expected_token/.test(error.message);
      }

      assertSelfTest("(d2) malformed direct append throws before rewrite", threw);
      assertSelfTest("(d2) malformed direct append leaves target spec byte-identical", fs.readFileSync(destAbs, "utf8") === before);
    }

    // (e) rows stay sorted by finding_id after 3 out-of-order appends.
    {
      const targetSpecPath = "accrue_admin/e2e/reduced-motion.spec.js";
      const fakeRepo = fs.mkdtempSync(path.join(root, "repo-sort-"));
      const destAbs = path.join(fakeRepo, targetSpecPath);
      fs.mkdirSync(path.dirname(destAbs), { recursive: true });
      fs.copyFileSync(path.join(REPO_ROOT, targetSpecPath), destAbs);

      for (const seed of [0x33, 0x31, 0x32]) {
        const { row } = mintGuardRow(
          { finding_id: hex16(seed), dimension: 9 },
          { route: "/billing/dev/components", selector: ".ax-dropdown-panel", max_ms: 1 }
        );
        appendMintedRow(targetSpecPath, row, fakeRepo);
      }

      const finalText = fs.readFileSync(destAbs, "utf8");
      const { bodyStart, closeIdx } = locateRegion(finalText);
      const rows = parseExistingRows(finalText.slice(bodyStart, closeIdx));
      const ids = rows.map((r) => r.finding_id);
      const sortedIds = [...ids].sort();
      assertSelfTest(
        "(e) 3 out-of-order appends land sorted ascending by finding_id",
        JSON.stringify(ids) === JSON.stringify(sortedIds) && ids.length === 3,
        JSON.stringify(ids)
      );
    }

    console.log("ratchet-guard-mint self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// -----------------------------------------------------------------------------
// CLI entry point — `--self-test` only (this module is a library for 207-06 otherwise).
// -----------------------------------------------------------------------------
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    if (process.argv.includes("--self-test")) {
      runSelfTest();
    } else {
      console.error("ratchet-guard-mint.mjs is a library; run with --self-test to self-verify.");
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(`ratchet-guard-mint.mjs crashed: ${error.message}`);
    process.exitCode = 1;
  }
}

export {
  kindForFinding,
  homeSpecForKind,
  requiredFieldsForKind,
  missingRequiredFields,
  mintGuardRow,
  appendMintedRow,
};
