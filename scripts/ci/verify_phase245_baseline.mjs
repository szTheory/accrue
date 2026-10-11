#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const args = process.argv.slice(2);
const opts = {};
for (let index = 0; index < args.length; index += 1) {
  if (args[index].startsWith("--")) opts[args[index].slice(2)] = args[index + 1] && !args[index + 1].startsWith("--") ? args[++index] : true;
}
const coveragePath = path.resolve(root, opts.coverage ?? ".planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md");
const manifestPath = path.resolve(root, opts.manifest ?? ".planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json");
const findingsPath = path.resolve(root, opts.findings ?? ".planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md");
const errors = [];
const fail = (message) => errors.push(message);

function jsonBlock(markdown, label) {
  const match = markdown.match(new RegExp(`<!-- ${label}-json:start -->([\\s\\S]*?)<!-- ${label}-json:end -->`));
  if (!match) throw new Error(`missing ${label} JSON block`);
  return JSON.parse(match[1].trim());
}

function mountedRoutes() {
  const pkg = fs.readFileSync(path.join(root, "accrue_admin/lib/accrue_admin/router.ex"), "utf8");
  const host = fs.readFileSync(path.join(root, "examples/accrue_host/lib/accrue_host_web/router.ex"), "utf8");
  if (!host.includes("import AccrueAdmin.Router") || !host.includes('accrue_admin("/admin"')) {
    throw new Error("host router no longer imports and mounts accrue_admin at /admin");
  }
  const routes = [];
  let analytics = false;
  let dev = false;
  for (const line of pkg.split("\n")) {
    if (/scope\s+"\/analytics"/.test(line)) analytics = true;
    if (/if\s+dev_routes\?/.test(line)) dev = true;
    const live = line.match(/live\("([^"]+)"/);
    if (live) {
      const local = live[1];
      routes.push({ route: `/admin${analytics ? "/analytics" : ""}${local === "/" ? "" : local}`, development: dev });
    }
    if (analytics && /^\s*end\s*$/.test(line)) analytics = false;
    if (dev && /^\s*end\s*$/.test(line)) dev = false;
  }
  return routes;
}

try {
  const coverageText = fs.readFileSync(coveragePath, "utf8");
  const coverage = jsonBlock(coverageText, "coverage");
  if (!Array.isArray(coverage.rows) || coverage.rows.length === 0) fail("coverage rows are empty");
  const ids = new Set();
  const orderedRows = [...(coverage.rows ?? [])].sort((left, right) => left.route.localeCompare(right.route) || left.id.localeCompare(right.id));
  if (JSON.stringify(orderedRows) !== JSON.stringify(coverage.rows ?? [])) fail("route-state rows are not deterministically sorted by route then ID");
  for (const row of coverage.rows ?? []) {
    if (!row.id || ids.has(row.id)) fail(`missing or duplicate route-state id: ${row.id ?? "<empty>"}`);
    ids.add(row.id);
    if (!row.route || !row.state || !row.url || !row.visual_anchor) fail(`incomplete route-state row: ${row.id}`);
    if (!["inspected", "unavailable", "not-applicable"].includes(row.status)) fail(`unknown status in ${row.id}: ${row.status}`);
    if (["unavailable", "not-applicable"].includes(row.status) && !row.reason) fail(`missing reason in ${row.id}`);
    if (row.status === "inspected" && !row.evidence) fail(`inspected row has no evidence in ${row.id}`);
  }
  const expected = mountedRoutes().filter((row) => !row.development).map((row) => row.route).sort();
  const production = [...new Set((coverage.routes ?? []).filter((row) => row.kind === "production-liveview").map((row) => row.route))].sort();
  if (JSON.stringify(production) !== JSON.stringify(expected)) {
    fail(`production route templates differ from mounted router; expected ${expected.length}, got ${production.length}; missing=${expected.filter((route) => !production.includes(route)).join(",")}; extra=${production.filter((route) => !expected.includes(route)).join(",")}`);
  }
  for (const route of expected) {
    if (!(coverage.rows ?? []).some((row) => row.route === route && ["inspected", "unavailable", "not-applicable"].includes(row.status))) fail(`no classified state for mounted route ${route}`);
  }
  if ((coverage.routes ?? []).filter((row) => row.kind === "production-liveview").length !== expected.length) fail("production route inventory contains duplicates");
  if (!Array.isArray(coverage.state_matrix) || coverage.state_matrix.length === 0) fail("material state matrix is missing");
  for (const state of coverage.state_matrix ?? []) if (!state.id || !state.applies_to || !state.state || !["inspected", "unavailable", "not-applicable"].includes(state.status) || !state.reason) fail(`incomplete material state row ${state.id ?? "<empty>"}`);
  const declaredPriorCount = coverage.prior_route_count;
  if (declaredPriorCount !== 21 || expected.length !== declaredPriorCount) fail(`stale historical route-count reconciliation: prior=${declaredPriorCount}, current=${expected.length}`);
  if (!opts["routes-only"]) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    if (!Array.isArray(manifest.captures) || manifest.captures.length === 0) fail("manifest has no captures");
    const combos = new Set();
    for (const capture of manifest.captures ?? []) {
      if (!capture.source_revision || typeof capture.source_dirty !== "boolean" || !capture.route || !capture.state || !capture.viewport || !capture.theme || !capture.scenario || !capture.source_digests || !capture.assets || !capture.browser || !capture.captured_at) fail(`incomplete provenance for ${capture.id ?? capture.route}`);
      const screenshotPath = path.resolve(root, capture.png?.path ?? "");
      if (!screenshotPath.startsWith(path.join(root, ".planning/phases/245-rendered-baseline-and-realistic-preview/captures") + path.sep)) fail(`PNG escapes phase capture directory: ${capture.id}`);
      if (!fs.existsSync(screenshotPath)) fail(`missing PNG ${capture.png?.path}`);
      else {
        const digest = crypto.createHash("sha256").update(fs.readFileSync(screenshotPath)).digest("hex");
        if (digest !== capture.png.sha256) fail(`PNG hash mismatch ${capture.png.path}`);
      }
      if (capture.assets.css?.package !== capture.assets.css?.compiled || capture.assets.css?.package !== capture.assets.css?.served || capture.assets.js?.package !== capture.assets.js?.compiled || capture.assets.js?.package !== capture.assets.js?.served) fail(`package/compiled/served assets differ for ${capture.id}`);
      if (capture.assets.css?.requested_by_document !== true || capture.assets.js?.requested_by_document !== true) fail(`served assets were not observed as document requests for ${capture.id}`);
      combos.add(`${capture.viewport.width}x${capture.viewport.height}:${capture.theme}`);
    }
    for (const combo of ["1280x900:light", "1280x900:dark", "390x844:light", "390x844:dark"]) if (!combos.has(combo)) fail(`required representative viewport/theme missing: ${combo}`);
    if (!coverage.omitted_combinations?.length) fail("omitted state combinations are not enumerated");

    const findings = fs.readFileSync(findingsPath, "utf8");
    const items = jsonBlock(findings, "owner-items");
    if (!Array.isArray(items) || items.length < 12) fail("owner brief traceability list is missing high-signal items");
    for (const item of items ?? []) {
      if (!item.topic || !item.disposition || !item.owner || !item.source) fail(`owner brief item lacks source/owner/disposition: ${item.topic ?? "<empty>"}`);
      if (item.disposition === "finding" && (!item.finding || !item.route_state || !item.capture_hash)) fail(`accepted owner finding lacks evidence: ${item.topic}`);
    }
    const findingRows = jsonBlock(findings, "findings");
    for (const finding of findingRows ?? []) {
      if (!finding.id || !finding.route_state || !finding.capture_hash || !finding.source || !finding.owner || !finding.severity || !finding.disposition) fail(`incomplete finding ${finding.id ?? "<empty>"}`);
      const capture = (manifest.captures ?? []).find((candidate) => candidate.png?.sha256 === finding.capture_hash);
      if (!capture || capture.route_state !== finding.route_state) fail(`finding ${finding.id} references no matching manifest capture`);
    }
  }
} catch (error) {
  fail(error.message);
}

if (errors.length) {
  console.error(errors.map((error) => `FAIL: ${error}`).join("\n"));
  process.exitCode = 1;
} else {
  console.log(`PASS: ${opts["routes-only"] ? "route inventory" : "route inventory, capture manifest and findings"}`);
}
