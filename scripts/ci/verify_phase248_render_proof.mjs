#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const definitions = new Map([
  ["ordinary-invoice-review", { lane: "ordinary", route: /^\/admin\/invoices\/[0-9a-f-]+$/i, sizes: ["1280x900:light", "320x820:dark"] }],
  ["empty-subscriptions", { lane: "heldout", route: "/admin/subscriptions", sizes: ["1280x900:light", "320x820:dark"] }],
  ["failed-webhook", { lane: "heldout", route: /^\/admin\/webhooks\/[0-9a-f-]+$/i, sizes: ["1280x900:dark", "320x820:light"] }],
  ["long-name-boundary", { lane: "heldout", route: /^\/admin\/customers\/[0-9a-f-]+$/i, sizes: ["1280x900:dark", "320x820:light"] }]
]);
const harnessOnly = new Set([
  "examples/accrue_host/e2e/phase248-scenarios.spec.js",
  "examples/accrue_host/e2e/phase248-heldout-setup.js",
  "examples/accrue_host/e2e/support/fixture.js",
  "examples/accrue_host/e2e/support/test.js",
  "examples/accrue_host/playwright.phase248-ordinary.config.js",
  "examples/accrue_host/playwright.phase248-heldout.config.js",
  "scripts/ci/accrue_host_seed_e2e.exs",
  "scripts/ci/seed_phase245_ordinary.sh",
  "scripts/ci/verify_phase248_render_proof.mjs"
]);
const hash = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const fail = (message) => { throw new Error(message); };
const check = (condition, message) => { if (!condition) fail(message); };

function repoFile(relative) {
  check(typeof relative === "string" && !path.isAbsolute(relative) && !relative.split(/[\\/]/).includes(".."), `unsafe repository path: ${relative}`);
  const absolute = path.resolve(repo, relative);
  check(absolute.startsWith(`${repo}${path.sep}`), `path escapes repository: ${relative}`);
  return absolute;
}

function noSecrets(value, where = "manifest") {
  if (Array.isArray(value)) return value.forEach((item, index) => noSecrets(item, `${where}[${index}]`));
  if (!value || typeof value !== "object") return;
  for (const [key, nested] of Object.entries(value)) {
    check(!/(password|secret|cookie|authorization|request.?headers|session.?token)/i.test(key), `secret-bearing key ${where}.${key}`);
    noSecrets(nested, `${where}.${key}`);
  }
}

const args = process.argv.slice(2);
check(args.length === 2 || args.length === 4, "usage: node verify_phase248_render_proof.mjs --manifest <repo-relative-path> [--scenario ordinary]");
check(args[0] === "--manifest", "manifest path is required");
let scenarioFilter = null;
if (args.length === 4) {
  check(args[2] === "--scenario" && args[3] === "ordinary", "only the ordinary tracer slice may be selected independently");
  scenarioFilter = args[3];
}
const manifestPath = repoFile(args[1]);
const captureRoot = path.dirname(manifestPath);
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
noSecrets(manifest);
check(manifest.phase === "248" && Array.isArray(manifest.captures), "unexpected Phase 248 manifest shape");
const captures = scenarioFilter
  ? manifest.captures.filter((capture) => capture.origin_lane === "ordinary")
  : manifest.captures;
check(captures.length > 0, "manifest contains no selected captures");
const sourceSha = captures[0]?.source_sha;
check(/^[a-f0-9]{40}$/.test(sourceSha || ""), "invalid captured source SHA");
execFileSync("git", ["cat-file", "-e", `${sourceSha}^{commit}`], { cwd: repo, stdio: "ignore" });
check(execFileSync("git", ["merge-base", "--is-ancestor", sourceSha, "HEAD"], { cwd: repo, stdio: "ignore" }) !== undefined, "captured source is not in current history");
const first = captures[0];
check(first.source_digests && typeof first.source_digests === "object", "missing captured source digests");
for (const [source, expectedDigest] of Object.entries(first.source_digests)) {
  check(/^[a-f0-9]{64}$/.test(expectedDigest), `invalid SHA-256 for ${source}`);
  const committed = execFileSync("git", ["show", `${sourceSha}:${source}`], { cwd: repo });
  check(hash(committed) === expectedDigest, `captured source digest differs at tested commit: ${source}`);
  if (!harnessOnly.has(source)) check(hash(fs.readFileSync(repoFile(source))) === expectedDigest, `current product source differs from tested source: ${source}`);
}
for (const required of ["accrue_admin/lib/accrue_admin/live/invoice_live.ex", "accrue_admin/lib/accrue_admin/live/subscription_live.ex", "accrue_admin/lib/accrue_admin/live/webhook_live.ex", "accrue_admin/priv/static/accrue_admin.css", "accrue_admin/priv/static/accrue_admin.js"]) {
  check(Object.hasOwn(first.source_digests, required), `missing source evidence: ${required}`);
}

const seen = new Set();
const seenScenarios = new Set();
const assetsByLane = new Map();
for (const capture of captures) {
  check(capture.source_sha === sourceSha, "capture source SHAs differ");
  const scenario = capture.scenario;
  const definition = definitions.get(scenario);
  check(definition && definition.lane === capture.origin_lane, `unknown scenario/lane: ${capture.origin_lane}/${scenario}`);
  check(typeof definition.route === "string" ? capture.route === definition.route : definition.route.test(capture.route), `route does not match scenario ${scenario}: ${capture.route}`);
  const viewport = capture.viewport;
  const viewportKey = `${viewport?.width}x${viewport?.height}`;
  const matrixKey = `${viewportKey}:${capture.theme}`;
  check(definition.sizes.includes(matrixKey), `unexpected viewport/theme for ${scenario}: ${matrixKey}`);
  const rowKey = `${scenario}:${matrixKey}`;
  check(!seen.has(rowKey), `duplicate matrix row: ${rowKey}`);
  seen.add(rowKey);
  seenScenarios.add(scenario);
  check(capture.file === `${capture.origin_lane}-${scenario}-${viewport.width === 1280 ? "wide" : "narrow"}-${capture.theme}.png`, `capture filename does not match its matrix row: ${capture.file}`);
  check(capture.capture_mode === "viewport", `capture is not framed to its actual viewport: ${capture.file}`);
  check(capture.inspection_status === "inspected" && capture.inspection_by === "Impeccable visual inspection" && capture.inspected_at && capture.inspection_notes, `capture lacks documented full-size visual inspection: ${capture.file}`);
  check(capture.state === capture.checks?.state && capture.evidence_at && Object.keys(capture.checks).length > 0, `capture lacks state checks: ${capture.file}`);
  if (scenario === "empty-subscriptions") {
    check(capture.route === "/admin/subscriptions" && capture.checks.underlying_scoped_record_count === 0 && capture.checks.unfiltered === true, "empty state is not proved as a genuine unfiltered zero-record collection");
  }
  if (scenario === "failed-webhook") check(/dead|discarded|failed/i.test(capture.checks.observed_status || "") && capture.checks.action_submitted === false && typeof capture.checks.owner_scope === "string" && capture.checks.owner_scope.length > 0, "failure capture lacks owner scope, overstates, or submits the observed failure action");
  if (scenario === "long-name-boundary") check(capture.checks.exact_identity_accessible === true && capture.checks.narrow_page_dimensions?.scroll <= 320, "long-name boundary is missing its exact-identity or overflow assertion");

  const screenshot = repoFile(path.relative(repo, path.resolve(captureRoot, capture.file)));
  check(screenshot.startsWith(`${captureRoot}${path.sep}`) && fs.existsSync(screenshot) && !fs.lstatSync(screenshot).isSymbolicLink(), `missing, unsafe, or symlink image: ${capture.file}`);
  const bytes = fs.readFileSync(screenshot);
  check(hash(bytes) === capture.screenshot?.sha256 && bytes.length === capture.screenshot?.bytes, `image hash/size mismatch: ${capture.file}`);
  check(bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])), `image is not PNG: ${capture.file}`);
  check(bytes.readUInt32BE(16) === viewport.width && capture.screenshot_dimensions?.width === viewport.width, `PNG viewport width mismatch: ${capture.file}`);
  check(bytes.readUInt32BE(20) === capture.screenshot_dimensions?.height && capture.screenshot_dimensions.height === viewport.height, `PNG viewport height mismatch: ${capture.file}`);
  for (const kind of ["css", "js"]) {
    const asset = capture.assets?.[kind];
    check(asset && /^[a-f0-9]{64}$/.test(asset.sha256 || "") && Number.isInteger(asset.bytes) && asset.bytes > 0, `missing or invalid served ${kind} evidence`);
    check(hash(fs.readFileSync(repoFile(asset.path))) === asset.sha256, `served ${kind} digest does not match the built package: ${capture.file}`);
    const key = `${capture.origin_lane}:${kind}`;
    check(!assetsByLane.has(key) || assetsByLane.get(key) === asset.sha256, `served ${kind} changes inside ${capture.origin_lane} lane`);
    assetsByLane.set(key, asset.sha256);
  }
}

const requiredScenarios = scenarioFilter ? ["ordinary-invoice-review"] : [...definitions.keys()];
for (const scenario of requiredScenarios) {
  check(seenScenarios.has(scenario), `missing required scenario: ${scenario}`);
  for (const matrixKey of definitions.get(scenario).sizes) check(seen.has(`${scenario}:${matrixKey}`), `missing matrix row ${scenario} ${matrixKey}`);
}
check(captures.length === requiredScenarios.length * 2, `unexpected selected capture count: ${captures.length}`);
const pngFiles = fs.readdirSync(captureRoot).filter((name) => name.endsWith(".png"));
check(pngFiles.length === manifest.captures.length, `capture folder has ${pngFiles.length} PNGs for ${manifest.captures.length} manifest rows`);
console.log(`Validated ${captures.length} inspected Phase 248 render captures across ${requiredScenarios.length} scenario(s), source ${sourceSha.slice(0, 12)}, served CSS/JS and image digests match.`);
