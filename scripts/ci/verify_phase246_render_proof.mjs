#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const expectedFiles = new Map([
  ["ordinary-invoices-toolbar", ["/admin/invoices", "ordinary"]],
  ["ordinary-payments", ["/admin/payments", "ordinary"]],
  ["ordinary-coupons", ["/admin/coupons", "ordinary"]],
  ["ordinary-events", ["/admin/events", "ordinary"]],
  ["heldout-connect-accounts", ["/admin/connect", "heldout"]],
  ["heldout-webhooks", ["/admin/webhooks", "heldout"]]
]);
const sourceFiles = [
  "accrue_admin/lib/accrue_admin/live/invoices_live.ex",
  "accrue_admin/lib/accrue_admin/live/charges_live.ex",
  "accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex",
  "accrue_admin/lib/accrue_admin/live/coupons_live.ex",
  "accrue_admin/lib/accrue_admin/live/events_live.ex",
  "accrue_admin/lib/accrue_admin/live/webhooks_live.ex",
  "accrue_admin/lib/accrue_admin/components/data_table.ex",
  "accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex",
  "accrue_admin/lib/accrue_admin/components/id_badge.ex",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/js/hooks/clipboard.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/e2e/phase246-current-proof.spec.js",
  "examples/accrue_host/playwright.phase246.config.js",
  "examples/accrue_host/playwright.config.js",
  "scripts/ci/accrue_host_seed_e2e.exs",
  "scripts/ci/verify_phase246_render_proof.mjs"
];
// Render proof captures remain valid when only this harness/checker changes
// after a run, provided all product, fixture, and asset sources still match.
const harnessOnlySources = new Set([
  "examples/accrue_host/e2e/phase246-current-proof.spec.js",
  "scripts/ci/verify_phase246_render_proof.mjs"
]);
const sha = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const fail = (message) => { throw new Error(message); };
function check(condition, message) { if (!condition) fail(message); }
function repoFile(relative) {
  check(typeof relative === "string" && !path.isAbsolute(relative) && !relative.split(/[\\/]/).includes(".."), `unsafe repository path: ${relative}`);
  const absolute = path.resolve(repo, relative);
  check(absolute.startsWith(`${repo}${path.sep}`), `path escapes repository: ${relative}`);
  return absolute;
}
function noSecrets(value, where = "manifest") {
  if (Array.isArray(value)) return value.forEach((item, i) => noSecrets(item, `${where}[${i}]`));
  if (!value || typeof value !== "object") return;
  for (const [key, nested] of Object.entries(value)) {
    check(!/(password|secret|cookie|authorization|request.?headers|session.?token)/i.test(key), `secret-bearing key ${where}.${key}`);
    noSecrets(nested, `${where}.${key}`);
  }
}

const args = process.argv.slice(2);
const manifestArg = args[args.indexOf("--manifest") + 1];
check(args.length === 2 && args[0] === "--manifest" && manifestArg, "usage: node verify_phase246_render_proof.mjs --manifest <repo-relative-path>");
const manifestPath = repoFile(manifestArg);
const captureRoot = path.dirname(manifestPath);
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
noSecrets(manifest);
check(manifest.phase === "246" && Array.isArray(manifest.captures), "unexpected manifest shape");
check(manifest.captures.length === 24, `expected exactly 24 captures, found ${manifest.captures.length}`);

const sourceSha = manifest.captures[0]?.source_sha;
check(/^[a-f0-9]{40}$/.test(sourceSha || ""), "invalid source commit SHA");
execFileSync("git", ["cat-file", "-e", `${sourceSha}^{commit}`], { cwd: repo, stdio: "ignore" });
const seen = new Set();
const routesByLane = { ordinary: new Set(), heldout: new Set() };
const expectedSizes = new Set(["1280x900", "320x820"]);
const seenSizes = new Set();
const expectedThemes = new Set(["light", "dark"]);
const seenThemes = new Set();
const laneAssets = new Map();
for (const source of sourceFiles) {
  const entry = manifest.captures[0].source_digests?.[source];
  check(/^[a-f0-9]{64}$/.test(entry || ""), `missing source digest: ${source}`);
  const committed = execFileSync("git", ["show", `${sourceSha}:${source}`], { cwd: repo });
  check(sha(committed) === entry, `source digest does not match committed ${source}`);
  if (!harnessOnlySources.has(source)) {
    check(sha(fs.readFileSync(repoFile(source))) === entry, `working source differs from committed ${source}`);
  }
}

for (const capture of manifest.captures) {
  check(capture.source_sha === sourceSha, "capture source SHAs differ");
  check(["ordinary", "heldout"].includes(capture.origin_lane), `invalid lane: ${capture.origin_lane}`);
  const scenario = capture.scenario;
  const route = capture.route;
  const routeKey = `${capture.origin_lane}-${scenario.replace(/-(wide|narrow)-(light|dark)$/, "")}`;
  const baseScenario = scenario.replace(/-(wide|narrow)-(light|dark)$/, "");
  const expectation = expectedFiles.get(routeKey);
  check(expectation, `unexpected capture scenario/lane ${routeKey}`);
  check(route === expectation[0] && capture.origin_lane === expectation[1], `wrong route/lane for ${routeKey}`);
  const shape = `${capture.viewport?.width}x${capture.viewport?.height}`;
  check(expectedSizes.has(shape), `invalid viewport: ${shape}`);
  check(expectedThemes.has(capture.theme), `invalid theme: ${capture.theme}`);
  seenSizes.add(shape); seenThemes.add(capture.theme);
  const key = `${routeKey}:${shape}:${capture.theme}`;
  check(!seen.has(key), `duplicate matrix entry ${key}`); seen.add(key);
  routesByLane[capture.origin_lane].add(route);
  check(capture.file === `${routeKey}-${shape === "1280x900" ? "wide" : "narrow"}-${capture.theme}.png`, `capture filename does not match matrix: ${capture.file}`);
  check(capture.capture_mode === undefined || capture.capture_mode === "full_page", `capture is not full-page evidence: ${capture.file}`);
  const pngPath = path.resolve(captureRoot, capture.file);
  check(pngPath.startsWith(`${captureRoot}${path.sep}`) && fs.existsSync(pngPath), `missing or unsafe PNG ${capture.file}`);
  const bytes = fs.readFileSync(pngPath);
  check(sha(bytes) === capture.screenshot?.sha256 && bytes.length === capture.screenshot?.bytes, `PNG hash/size mismatch: ${capture.file}`);
  check(bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])), `not a PNG: ${capture.file}`);
  check(bytes.readUInt32BE(16) === capture.viewport.width && bytes.readUInt32BE(20) >= capture.viewport.height, `PNG dimensions are inconsistent with viewport: ${capture.file}`);
  const assets = capture.assets;
  check(assets && assets.css && assets.js, `missing fetched asset digests: ${capture.file}`);
  for (const kind of ["css", "js"]) {
    const asset = assets[kind];
    check(/^[a-f0-9]{64}$/.test(asset.sha256 || ""), `invalid ${kind} digest`);
    check(sha(fs.readFileSync(repoFile(asset.path))) === asset.sha256, `${kind} served asset differs from local build`);
    const previous = laneAssets.get(`${capture.origin_lane}:${kind}`);
    check(!previous || previous === asset.sha256, `${kind} differs within ${capture.origin_lane} lane`);
    laneAssets.set(`${capture.origin_lane}:${kind}`, asset.sha256);
  }
}
check(seen.size === 24 && seenSizes.size === 2 && seenThemes.size === 2, "incomplete route/viewport/theme matrix");
for (const [scenario, [route, lane]] of expectedFiles) {
  check(routesByLane[lane].has(route), `missing route ${route} in ${lane} lane`);
  for (const size of expectedSizes) for (const theme of expectedThemes) {
    check(seen.has(`${lane}-${scenario.replace(`${lane}-`, "")}:${size}:${theme}`) || seen.has(`${scenario}:${size}:${theme}`), `missing ${scenario} ${size} ${theme}`);
  }
}
const actualFiles = fs.readdirSync(captureRoot).filter((name) => name.endsWith(".png") && name !== "montage.png").sort();
check(actualFiles.length === 24 && actualFiles.every((name) => seen.has(`${name.replace(/-(wide|narrow)-(light|dark)\.png$/, "")}:${name.includes("-wide-") ? "1280x900" : "320x820"}:${name.endsWith("-light.png") ? "light" : "dark"}`)), "capture directory contains extra or missing PNGs");
console.log(`Validated 24 PNGs across four ordinary and two held-out routes; source ${sourceSha.slice(0, 12)}; CSS/JS fetched asset digests match package builds.`);
