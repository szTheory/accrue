#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import os from "node:os";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";
import assert from "node:assert/strict";
import { isMainModule } from "./main_module.mjs";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

function registerTests() {
  // Hermetic: the built-in self-test refreshes capture source digests into a temp fixture,
  // proves the refreshed fixture passes, and proves a stale digest is rejected.
  test("self-test passes refreshed-digest fixture and rejects a stale source digest", () => {
    const env = { ...process.env };
    delete env.NODE_TEST_CONTEXT;
    const result = spawnSync(process.execPath, [fileURLToPath(import.meta.url), "--self-test"], { encoding: "utf8", shell: false, env });
    assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
    assert.match(result.stdout, /refreshed-positive=1/);
    assert.match(result.stdout, /stale-source-digest-rejected=1/);
  });
}

function main() {
const args = process.argv.slice(2);
const opts = {};
for (let index = 0; index < args.length; index += 1) {
  if (args[index].startsWith("--")) opts[args[index].slice(2)] = args[index + 1] && !args[index + 1].startsWith("--") ? args[++index] : true;
}
const PHASE245 = "245-rendered-baseline-and-realistic-preview";
// Recorded commands pass `.planning/phases/<slug>/<rest>`; after milestone archival the
// directory lives under `.planning/milestones/*-phases/`, so resolve through the canonical resolver.
function resolveEvidenceInput(input) {
  const match = typeof input === "string" ? input.match(/^\.planning\/phases\/(\d+-[a-z0-9]+(?:-[a-z0-9]+)*)\/(.+)$/) : null;
  if (match && !fs.existsSync(path.resolve(root, input))) return resolvePhaseEvidencePath(match[1], match[2], { root });
  return path.resolve(root, input);
}
let coveragePath;
let manifestPath;
let findingsPath;
try {
  coveragePath = opts.coverage ? resolveEvidenceInput(opts.coverage) : resolvePhaseEvidencePath(PHASE245, "245-COVERAGE.md", { root });
  manifestPath = opts.manifest ? resolveEvidenceInput(opts.manifest) : resolvePhaseEvidencePath(PHASE245, "captures/manifest.json", { root });
  findingsPath = opts.findings ? resolveEvidenceInput(opts.findings) : resolvePhaseEvidencePath(PHASE245, "245-FINDINGS.md", { root });
} catch (error) {
  console.error(`FAIL: ${error.message}`);
  process.exit(1);
}
if (args.includes("--self-test")) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "phase245-verifier-"));
  let sourceCoverage = fs.readFileSync(coveragePath, "utf8");
  const sourceManifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const sourceFindings = fs.readFileSync(findingsPath, "utf8");
  const manifest = structuredClone(sourceManifest);
  for (const capture of manifest.captures ?? []) {
    capture.source_dirty = false;
    const refreshed = {};
    for (const sourcePath of Object.keys(capture.source_digests ?? {})) {
      const absolute = path.resolve(root, sourcePath);
      if (!absolute.startsWith(root + path.sep) || !fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) continue;
      refreshed[sourcePath] = crypto.createHash("sha256").update(fs.readFileSync(absolute)).digest("hex");
    }
    capture.source_digests = refreshed;
  }
  const coverageBlock = sourceCoverage.match(/<!-- coverage-json:start -->([\s\S]*?)<!-- coverage-json:end -->/);
  const positiveCoverage = JSON.parse(coverageBlock[1].trim());
  for (const capture of manifest.captures ?? []) {
    const row = positiveCoverage.rows.find((candidate) => candidate.id === capture.route_state);
    if (row) {
      row.url = capture.url;
      row.visual_anchor = "Visible route heading: self-test rendered identity";
    }
    capture.rendered_identity = { heading: "self-test rendered identity", selector: "main h1" };
  }
  sourceCoverage = sourceCoverage.replace(/<!-- coverage-json:start -->[\s\S]*?<!-- coverage-json:end -->/, `<!-- coverage-json:start -->\n${JSON.stringify(positiveCoverage, null, 2)}\n<!-- coverage-json:end -->`);
  const coverageFile = path.join(tempDir, "coverage.md");
  const manifestFile = path.join(tempDir, "manifest.json");
  const findingsFile = path.join(tempDir, "findings.md");
  fs.writeFileSync(coverageFile, sourceCoverage);
  fs.writeFileSync(manifestFile, JSON.stringify(manifest));
  fs.writeFileSync(findingsFile, sourceFindings);
  const run = () => spawnSync(process.execPath, [fileURLToPath(import.meta.url), "--coverage", coverageFile, "--manifest", manifestFile, "--findings", findingsFile], { encoding: "utf8" });
  const requireFailure = (label, expectedText) => {
    const result = run();
    const output = `${result.stdout}\n${result.stderr}`;
    if (result.status === 0 || !output.includes(expectedText)) throw new Error(`${label} negative control was not rejected: ${output}`);
  };
  try {
    const positive = run();
    if (positive.status !== 0) throw new Error(`refreshed positive fixture failed: ${positive.stdout}\n${positive.stderr}`);

    const originalManifest = fs.readFileSync(manifestFile, "utf8");
    const digestFixture = structuredClone(manifest);
    const firstCapture = digestFixture.captures[0];
    firstCapture.source_digests[Object.keys(firstCapture.source_digests)[0]] = "0".repeat(64);
    fs.writeFileSync(manifestFile, JSON.stringify(digestFixture));
    requireFailure("stale source digest", "source digest is stale");
    fs.writeFileSync(manifestFile, originalManifest);

    const routeFixture = structuredClone(manifest);
    routeFixture.captures[0].url = "http://accrue-host-phase245-ordinary.localhost/admin/not-the-captured-route";
    fs.writeFileSync(manifestFile, JSON.stringify(routeFixture));
    requireFailure("mismatched captured URL", "URL does not match its exact ordinary route template");
    fs.writeFileSync(manifestFile, originalManifest);

    fs.writeFileSync(findingsFile, sourceFindings.replace('"topic":"Search control and dialog"', '"topic":"Webhook detail"'));
    requireFailure("missing/duplicate owner topic", "owner brief topic must appear exactly once");
    fs.writeFileSync(findingsFile, sourceFindings);

    const jsonMatch = sourceCoverage.match(/<!-- coverage-json:start -->([\s\S]*?)<!-- coverage-json:end -->/);
    const coverage = JSON.parse(jsonMatch[1].trim());
    const targetRoute = coverage.routes.find((entry) => entry.kind === "production-liveview").route;
    const targetRow = coverage.rows.find((row) => row.route === targetRoute);
    targetRow.status = "unavailable";
    targetRow.reason = "not inspected";
    fs.writeFileSync(coverageFile, sourceCoverage.replace(/<!-- coverage-json:start -->[\s\S]*?<!-- coverage-json:end -->/, `<!-- coverage-json:start -->\n${JSON.stringify(coverage, null, 2)}\n<!-- coverage-json:end -->`));
    requireFailure("generic unavailable route", "generic unavailable reason");
    console.log("self-test: refreshed-positive=1 stale-source-digest-rejected=1 mismatched-route-rejected=1 duplicate-owner-topic-rejected=1 generic-unavailable-rejected=1");
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
  process.exit(0);
}
const errors = [];
const fail = (message) => errors.push(message);
const requiredOwnerTopics = [
  "Search control and dialog", "Webhook detail", "Coupons and demo scenarios",
  "Connect collection and shared filter design", "Promotion codes and shared timestamp/table conventions",
  "Events collection", "Recovery analytics", "Payments collection",
  "Invoices collection and task-based filter behavior", "Subscriptions collection",
  "Customers and selective semantic emphasis", "Proposed milestone brief and evidence contract",
  "Working direction"
];

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

function matchesRouteTemplate(template, pathname) {
  const pattern = new RegExp(`^${template.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/:[^/]+/g, "[^/]+")}$`);
  return pattern.test(pathname);
}

try {
  const coverageText = fs.readFileSync(coveragePath, "utf8");
  const coverage = jsonBlock(coverageText, "coverage");
  if (!Array.isArray(coverage.rows) || coverage.rows.length === 0) fail("coverage rows are empty");
  const ids = new Set();
  const routeStates = new Set();
  const orderedRows = [...(coverage.rows ?? [])].sort((left, right) => left.route.localeCompare(right.route) || left.id.localeCompare(right.id));
  if (JSON.stringify(orderedRows) !== JSON.stringify(coverage.rows ?? [])) fail("route-state rows are not deterministically sorted by route then ID");
  for (const row of coverage.rows ?? []) {
    if (!row.id || ids.has(row.id)) fail(`missing or duplicate route-state id: ${row.id ?? "<empty>"}`);
    ids.add(row.id);
    const routeStateKey = `${row.route}\u0000${row.state}`;
    if (routeStates.has(routeStateKey)) fail(`duplicate route/state row: ${row.route} (${row.state})`);
    routeStates.add(routeStateKey);
    if (!row.route || !row.state || (!row.url && row.status === "inspected") || !row.visual_anchor) fail(`incomplete route-state row: ${row.id}`);
    if (!["inspected", "unavailable", "not-applicable"].includes(row.status)) fail(`unknown status in ${row.id}: ${row.status}`);
    if (["unavailable", "not-applicable"].includes(row.status) && !row.reason) fail(`missing reason in ${row.id}`);
    if (row.status === "unavailable" && /^(not inspected|unavailable|not available|could not inspect|not tested)[.! ]*$/i.test(row.reason ?? "")) fail(`generic unavailable reason in ${row.id}`);
    if (row.status === "inspected" && !row.evidence) fail(`inspected row has no evidence in ${row.id}`);
  }
  const expected = mountedRoutes().filter((row) => !row.development).map((row) => row.route).sort();
  const production = [...new Set((coverage.routes ?? []).filter((row) => row.kind === "production-liveview").map((row) => row.route))].sort();
  if (JSON.stringify(production) !== JSON.stringify(expected)) {
    fail(`production route templates differ from mounted router; expected ${expected.length}, got ${production.length}; missing=${expected.filter((route) => !production.includes(route)).join(",")}; extra=${production.filter((route) => !expected.includes(route)).join(",")}`);
  }
  for (const route of expected) {
    const rows = (coverage.rows ?? []).filter((row) => row.route === route);
    if (!rows.some((row) => ["inspected", "unavailable"].includes(row.status))) fail(`no inspected or evidence-backed unavailable state for mounted route ${route}`);
    if (rows.some((row) => row.status === "not-applicable")) fail(`mounted production route cannot be marked not-applicable: ${route}`);
    for (const row of rows.filter((candidate) => candidate.status === "unavailable")) {
      if (!/(no ordinary|no response|returned|ended at|remained|not rendered|cannot be formed|could not|not available in the ordinary)/i.test(row.reason ?? "")) fail(`unavailable route lacks concrete observation in ${row.id}`);
    }
  }
  const inspectedProduction = (coverage.rows ?? []).filter((row) => expected.includes(row.route) && row.status === "inspected").length;
  if (inspectedProduction < Math.ceil(expected.length / 2)) fail(`too few mounted production routes were inspected: ${inspectedProduction}/${expected.length}`);
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
      if (!/^[a-f0-9]{40,64}$/.test(capture.source_revision ?? "") || capture.source_revision !== manifest.source_revision) fail(`capture ${capture.id} is not bound to the manifest source revision`);
      if (capture.source_dirty !== false) fail(`capture ${capture.id} was made from dirty source; recapture from a clean committed source revision`);
      if (!capture.source_digests || Array.isArray(capture.source_digests) || typeof capture.source_digests !== "object" || Object.keys(capture.source_digests).length === 0) fail(`capture ${capture.id} has no source digest map`);
      for (const [sourcePath, expectedDigest] of Object.entries(capture.source_digests ?? {})) {
        const absoluteSource = path.resolve(root, sourcePath);
        if (path.isAbsolute(sourcePath) || absoluteSource !== root && !absoluteSource.startsWith(root + path.sep)) {
          fail(`capture ${capture.id} source path escapes repository: ${sourcePath}`);
          continue;
        }
        if (!/^[a-f0-9]{64}$/.test(expectedDigest)) { fail(`capture ${capture.id} has malformed SHA-256 for ${sourcePath}`); continue; }
        if (!fs.existsSync(absoluteSource) || !fs.statSync(absoluteSource).isFile()) { fail(`capture ${capture.id} source is missing: ${sourcePath}`); continue; }
        const actualDigest = crypto.createHash("sha256").update(fs.readFileSync(absoluteSource)).digest("hex");
        if (actualDigest !== expectedDigest) fail(`capture ${capture.id} source digest is stale for ${sourcePath}`);
      }
      const recordedPng = capture.png?.path ?? "";
      let screenshotPath = null;
      if (!recordedPng.startsWith(`.planning/phases/${PHASE245}/captures/`) || recordedPng.split("/").includes("..")) fail(`PNG escapes phase capture directory: ${capture.id}`);
      else {
        try {
          screenshotPath = resolvePhaseEvidencePath(PHASE245, recordedPng.slice(`.planning/phases/${PHASE245}/`.length), { root });
          const capturesDir = resolvePhaseEvidencePath(PHASE245, "captures", { root });
          if (!screenshotPath.startsWith(capturesDir + path.sep)) { fail(`PNG escapes phase capture directory: ${capture.id}`); screenshotPath = null; }
        } catch { screenshotPath = null; }
      }
      if (!screenshotPath || !fs.existsSync(screenshotPath)) fail(`missing PNG ${capture.png?.path}`);
      else {
        const digest = crypto.createHash("sha256").update(fs.readFileSync(screenshotPath)).digest("hex");
        if (digest !== capture.png.sha256) fail(`PNG hash mismatch ${capture.png.path}`);
      }
      if (capture.assets.css?.package !== capture.assets.css?.compiled || capture.assets.css?.package !== capture.assets.css?.served || capture.assets.js?.package !== capture.assets.js?.compiled || capture.assets.js?.package !== capture.assets.js?.served) fail(`package/compiled/served assets differ for ${capture.id}`);
      if (capture.assets.css?.requested_by_document !== true || capture.assets.js?.requested_by_document !== true) fail(`served assets were not observed as document requests for ${capture.id}`);
      combos.add(`${capture.viewport.width}x${capture.viewport.height}:${capture.theme}`);
      const routeStateRow = (coverage.rows ?? []).find((row) => row.id === capture.route_state);
      if (!routeStateRow || routeStateRow.route !== capture.route || routeStateRow.state !== capture.state || routeStateRow.status !== "inspected") fail(`capture ${capture.id} has no matching inspected route-state row`);
      try {
        const capturedURL = new URL(capture.url);
        if (capturedURL.origin !== "http://accrue-host-phase245-ordinary.localhost" || !matchesRouteTemplate(capture.route, capturedURL.pathname)) fail(`capture ${capture.id} URL does not match its exact ordinary route template`);
        if (!routeStateRow || routeStateRow.url !== capture.url) fail(`capture ${capture.id} URL differs from its route-state evidence`);
      } catch {
        fail(`capture ${capture.id} has an invalid final URL`);
      }
      if (!capture.rendered_identity?.heading?.trim() || capture.rendered_identity?.selector !== "main h1") fail(`capture ${capture.id} has no route-specific rendered heading identity`);
      if (!routeStateRow?.visual_anchor?.includes(capture.rendered_identity?.heading ?? "\0")) fail(`capture ${capture.id} heading is absent from its visual anchor evidence`);
    }
    for (const combo of ["1280x900:light", "1280x900:dark", "390x844:light", "390x844:dark"]) if (!combos.has(combo)) fail(`required representative viewport/theme missing: ${combo}`);
    if (!coverage.omitted_combinations?.length) fail("omitted state combinations are not enumerated");

    const findings = fs.readFileSync(findingsPath, "utf8");
    const items = jsonBlock(findings, "owner-items");
    if (!Array.isArray(items)) fail("owner brief traceability list is missing");
    const topicCounts = new Map();
    for (const item of items ?? []) {
      const topic = typeof item.topic === "string" ? item.topic.trim() : "";
      topicCounts.set(topic, (topicCounts.get(topic) ?? 0) + 1);
      if (!item.topic || !item.disposition || !item.owner || !item.source) fail(`owner brief item lacks source/owner/disposition: ${item.topic ?? "<empty>"}`);
      if (!["finding", "follow-up-unverified", "source-observed", "no-change", "unavailable"].includes(item.disposition)) fail(`unknown owner brief disposition for ${item.topic ?? "<empty>"}`);
      if (item.disposition === "finding" && (!item.finding || !item.route_state || !item.capture_hash)) fail(`accepted owner finding lacks evidence: ${item.topic}`);
    }
    for (const topic of requiredOwnerTopics) if (topicCounts.get(topic) !== 1) fail(`owner brief topic must appear exactly once: ${topic} (found ${topicCounts.get(topic) ?? 0})`);
    for (const topic of topicCounts.keys()) if (!requiredOwnerTopics.includes(topic)) fail(`unexpected owner brief topic: ${topic || "<empty>"}`);
    const findingRows = jsonBlock(findings, "findings");
    for (const finding of findingRows ?? []) {
      if (!finding.id || !finding.route_state || !finding.capture_hash || !finding.source || !finding.owner || !finding.severity || !finding.disposition) fail(`incomplete finding ${finding.id ?? "<empty>"}`);
      const capture = (manifest.captures ?? []).find((candidate) => candidate.png?.sha256 === finding.capture_hash);
      if (!capture || capture.route_state !== finding.route_state) fail(`finding ${finding.id} references no matching manifest capture`);
      if (!finding.source || !finding.owner || !finding.severity || !finding.disposition) fail(`finding ${finding.id} lacks source, owner, severity, or disposition`);
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
}

let entry = false;
try {
  entry = isMainModule(import.meta.url);
} catch {
  entry = false;
}

if (entry && process.env.NODE_TEST_CONTEXT) {
  registerTests();
} else if (entry) {
  main();
}
