#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const expected = new Map([
  ["ordinary-invoice-action-review", { lane: "ordinary", route: /^\/admin\/invoices\/[^/]+$/ }],
  ["ordinary-payment-recovery", { lane: "ordinary", route: "/admin/analytics/recovery" }],
  ["heldout-webhook-populated-detail", { lane: "heldout", route: /^\/admin\/webhooks\/[^/]+$/ }],
  ["heldout-webhook-replay-review", { lane: "heldout", route: /^\/admin\/webhooks\/[^/]+$/ }]
]);
const harnessOnly = new Set([
  "examples/accrue_host/e2e/phase247-current-proof.spec.js",
  "scripts/ci/verify_phase247_render_proof.mjs"
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
check(args.length === 2 && args[0] === "--manifest", "usage: node verify_phase247_render_proof.mjs --manifest <repo-relative-path>");
const manifestPath = repoFile(args[1]);
const captureRoot = path.dirname(manifestPath);
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
noSecrets(manifest);
check(manifest.phase === "247" && Array.isArray(manifest.captures), "unexpected manifest shape");
check(manifest.captures.length >= 12 && manifest.captures.length <= 16, `expected 12–16 captures, found ${manifest.captures.length}`);

const sourceSha = manifest.captures[0]?.source_sha;
check(/^[a-f0-9]{40}$/.test(sourceSha || ""), "invalid captured source SHA");
execFileSync("git", ["cat-file", "-e", `${sourceSha}^{commit}`], { cwd: repo, stdio: "ignore" });
const expectedSizes = new Set(["1280x900", "320x820"]);
const expectedThemes = new Set(["light", "dark"]);
const seen = new Set();
const seenScenarios = new Set();
const laneAssets = new Map();
const first = manifest.captures[0];
check(first.source_digests && typeof first.source_digests === "object", "missing captured source digests");
for (const [source, digest] of Object.entries(first.source_digests)) {
  check(/^[a-f0-9]{64}$/.test(digest), `invalid SHA-256 for ${source}`);
  const committed = execFileSync("git", ["show", `${sourceSha}:${source}`], { cwd: repo });
  check(hash(committed) === digest, `captured source digest differs at captured commit: ${source}`);
  if (!harnessOnly.has(source)) check(hash(fs.readFileSync(repoFile(source))) === digest, `current product source differs from captured source: ${source}`);
}
for (const required of [
  "accrue_admin/lib/accrue_admin/live/webhook_live.ex",
  "accrue_admin/lib/accrue_admin/live/invoice_live.ex",
  "accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js"
]) check(Object.hasOwn(first.source_digests, required), `missing required source evidence: ${required}`);

for (const capture of manifest.captures) {
  check(capture.source_sha === sourceSha, "capture source SHAs differ");
  check(["ordinary", "heldout"].includes(capture.origin_lane), `invalid capture lane: ${capture.origin_lane}`);
  const scenario = capture.scenario;
  const definition = expected.get(`${capture.origin_lane}-${scenario}`);
  check(definition, `unexpected scenario/lane: ${capture.origin_lane}-${scenario}`);
  check(definition.lane === capture.origin_lane, `scenario is assigned to wrong lane: ${scenario}`);
  check(typeof definition.route === "string" ? capture.route === definition.route : definition.route.test(capture.route), `route does not match scenario: ${capture.route}`);
  const viewport = capture.viewport;
  const viewportKey = `${viewport?.width}x${viewport?.height}`;
  check(expectedSizes.has(viewportKey), `invalid viewport: ${viewportKey}`);
  check(expectedThemes.has(capture.theme), `invalid theme: ${capture.theme}`);
  const key = `${capture.origin_lane}-${scenario}:${viewportKey}:${capture.theme}`;
  check(!seen.has(key), `duplicate capture matrix row: ${key}`);
  seen.add(key);
  seenScenarios.add(`${capture.origin_lane}-${scenario}`);
  check(capture.file === `${capture.origin_lane}-${scenario}-${viewportKey.startsWith("1280") ? "wide" : "narrow"}-${capture.theme}.png`, `capture filename does not match its matrix row: ${capture.file}`);
  check(capture.capture_mode === "full_page", `capture mode must be full-page: ${capture.file}`);
  check(capture.inspection_status === "inspected" && capture.inspection_by === "Impeccable visual inspection" && capture.inspected_at, `capture has not been inspected: ${capture.file}`);
  const screenshot = repoFile(path.relative(repo, path.resolve(captureRoot, capture.file)));
  check(screenshot.startsWith(`${captureRoot}${path.sep}`) && fs.existsSync(screenshot) && !fs.lstatSync(screenshot).isSymbolicLink(), `missing, unsafe, or symlink image: ${capture.file}`);
  const bytes = fs.readFileSync(screenshot);
  check(hash(bytes) === capture.screenshot?.sha256 && bytes.length === capture.screenshot?.bytes, `image hash/size mismatch: ${capture.file}`);
  check(bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])), `image is not PNG: ${capture.file}`);
  const dimensions = capture.screenshot_dimensions;
  check(bytes.readUInt32BE(16) === viewport.width && dimensions?.width === viewport.width, `PNG width does not match viewport: ${capture.file}`);
  check(bytes.readUInt32BE(20) === dimensions.height && dimensions.height >= viewport.height, `PNG full-page dimensions are inconsistent: ${capture.file}`);
  check(capture.evidence_at && capture.checks && Object.keys(capture.checks).length > 0, `missing timestamped state checks: ${capture.file}`);

  check(capture.assets && capture.assets.css && capture.assets.js, `missing served CSS/JS evidence: ${capture.file}`);
  for (const kind of ["css", "js"]) {
    const asset = capture.assets[kind];
    check(/^[a-f0-9]{64}$/.test(asset.sha256 || "") && Number.isInteger(asset.bytes) && asset.bytes > 0, `invalid served ${kind} evidence`);
    check(hash(fs.readFileSync(repoFile(asset.path))) === asset.sha256, `served ${kind} differs from built package: ${capture.file}`);
    const laneKey = `${capture.origin_lane}:${kind}`;
    check(!laneAssets.has(laneKey) || laneAssets.get(laneKey) === asset.sha256, `${kind} changes within ${capture.origin_lane} lane`);
    laneAssets.set(laneKey, asset.sha256);
  }
}

check(seenScenarios.size === expected.size, `expected all ${expected.size} scenarios, saw ${seenScenarios.size}`);
for (const [scenario, definition] of expected) {
  const laneAndScenario = `${definition.lane}-${scenario}`;
  for (const size of expectedSizes) for (const theme of expectedThemes) {
    check(seen.has(`${laneAndScenario}:${size}:${theme}`), `missing matrix evidence ${laneAndScenario} ${size} ${theme}`);
  }
}
check(seen.size >= 12 && seen.size <= 16, `invalid matrix size: ${seen.size}`);
const pngFiles = fs.readdirSync(captureRoot).filter((name) => name.endsWith(".png")).sort();
check(pngFiles.length === seen.size, `capture directory contains ${pngFiles.length} PNGs for ${seen.size} manifest rows`);
console.log(`Validated ${seen.size} inspected Phase 247 images across ordinary and held-out detail/recovery states; source ${sourceSha.slice(0, 12)}; served CSS/JS match the captured build.`);
