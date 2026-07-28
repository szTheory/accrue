/**
 * ratchet-live-uat.mjs — machine UAT for Phase 207's two formerly-human smokes.
 *
 * Default mode:
 *   1. Capture dashboard-only screenshots through Playwright.
 *   2. Assert the capture scope wrote only dashboard PNG/.bbox artifacts.
 *   3. Run the live Anthropic proposer twice against the unchanged PNGs.
 *   4. Fail unless pass 2 reports cache_read_input_tokens and identity is stable.
 *
 * Generated evidence is written under test-results/ (gitignored). This command is
 * intended for local use or explicit workflow_dispatch only, never recurring CI.
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ADMIN_ROOT = path.resolve(__dirname, "../..");
const CAPTURE_ROOT = path.join(ADMIN_ROOT, "test-results/admin-visuals");
const PROOF_ROOT = path.join(ADMIN_ROOT, "test-results/ui-ratchet/live-uat");
const CANDIDATES_PATH = path.join(CAPTURE_ROOT, "candidates.ndjson");
const SCOPE = "dashboard";
const PROJECTS = ["chromium-desktop", "chromium-mobile"];
const CAPTURE_FILES = ["dashboard.png", "dashboard-dark.png", "dashboard.bbox.json", "dashboard-dark.bbox.json"];

const mode = process.argv.includes("--self-test")
  ? "self-test"
  : process.argv.includes("--capture-only")
    ? "capture-only"
    : process.argv.includes("--cache-smoke")
      ? "cache-smoke"
      : "full";

if (process.argv.includes("--help")) {
  console.log(`Usage:
  node e2e/ratchet/ratchet-live-uat.mjs
  node e2e/ratchet/ratchet-live-uat.mjs --capture-only
  node e2e/ratchet/ratchet-live-uat.mjs --cache-smoke
  node e2e/ratchet/ratchet-live-uat.mjs --self-test`);
  process.exit(0);
}

if (mode === "self-test") {
  runSelfTest();
  process.exit(0);
}

const summary = {
  schema_version: "ratchet-live-uat/1",
  generated_at: new Date().toISOString(),
  mode,
  scope: SCOPE,
  status: "running",
  capture: null,
  cache: null,
};

try {
  fs.rmSync(PROOF_ROOT, { recursive: true, force: true });
  fs.mkdirSync(PROOF_ROOT, { recursive: true });

  if (mode !== "cache-smoke") {
    runDashboardCapture();
  }
  summary.capture = assertDashboardCapture(CAPTURE_ROOT);

  if (mode !== "capture-only") {
    assertLiveKey();
    summary.cache = runCacheSmoke();
  }

  summary.status = "pass";
  writeSummary(summary);
  console.log(`[ratchet-live-uat] PASS ${mode}: wrote ${path.relative(ADMIN_ROOT, summaryPath())}`);
} catch (err) {
  summary.status = "fail";
  summary.error = err && err.message ? err.message : String(err);
  try {
    fs.mkdirSync(PROOF_ROOT, { recursive: true });
    writeSummary(summary);
  } catch {
    // Preserve the original failure.
  }
  console.error(`[ratchet-live-uat] FAIL ${mode}: ${summary.error}`);
  process.exit(1);
}

function runDashboardCapture() {
  fs.rmSync(CAPTURE_ROOT, { recursive: true, force: true });
  run("npx", ["playwright", "test", "e2e/admin-visuals.spec.js", "--workers=1"], {
    ...process.env,
    RATCHET_SURFACES: SCOPE,
    NO_COLOR: undefined,
  });
}

function runCacheSmoke() {
  const pass1 = runProposerPass(1);
  const pass2 = runProposerPass(2);
  const identity_stable = sameStringList(pass1.identities, pass2.identities);

  const result = {
    pass1,
    pass2,
    identity_stable,
  };

  if (pass2.cache_read_input_tokens <= 0) {
    throw new Error("ORCH-07 failed: proposer pass 2 reported zero cache_read_input_tokens");
  }
  if (!identity_stable) {
    throw new Error("ORCH-07 failed: claim_key/finding_id identity changed between proposer passes");
  }
  return result;
}

function runProposerPass(pass) {
  const usagePath = path.join(PROOF_ROOT, `propose-pass-${pass}-usage.ndjson`);
  const candidatesCopyPath = path.join(PROOF_ROOT, `candidates-pass-${pass}.ndjson`);

  run("node", ["e2e/ratchet/ratchet-propose.mjs"], {
    ...process.env,
    RATCHET_SURFACES: SCOPE,
    RATCHET_USAGE_LOG: usagePath,
    RATCHET_LIVE_UAT_PASS: String(pass),
  });

  if (!fs.existsSync(CANDIDATES_PATH)) {
    throw new Error(`Proposer pass ${pass} did not write ${path.relative(ADMIN_ROOT, CANDIDATES_PATH)}`);
  }
  fs.copyFileSync(CANDIDATES_PATH, candidatesCopyPath);

  const usageRows = readNdjson(usagePath);
  const candidateRows = readNdjson(candidatesCopyPath);
  const identities = identityList(candidateRows);
  const cache_read_input_tokens = usageRows.reduce(
    (sum, row) => sum + numberOrZero(row.cache_read_input_tokens ?? row.usage?.cache_read_input_tokens),
    0
  );

  return {
    usage_path: path.relative(ADMIN_ROOT, usagePath),
    candidates_path: path.relative(ADMIN_ROOT, candidatesCopyPath),
    usage_calls: usageRows.length,
    candidate_rows: candidateRows.length,
    identity_count: identities.length,
    identities,
    cache_read_input_tokens,
  };
}

function assertDashboardCapture(root) {
  const expected = PROJECTS.flatMap((project) => CAPTURE_FILES.map((file) => `${project}/${file}`)).sort();
  const actual = listFiles(root)
    .filter((file) => file.endsWith(".png") || file.endsWith(".bbox.json"))
    .sort();

  if (!sameStringList(actual, expected)) {
    throw new Error(
      [
        "ORCH-08 failed: dashboard capture artifact set did not match.",
        `Expected: ${expected.join(", ")}`,
        `Actual: ${actual.join(", ") || "(none)"}`,
      ].join(" ")
    );
  }

  return {
    root: path.relative(ADMIN_ROOT, root),
    expected_artifacts: expected,
    actual_artifacts: actual,
  };
}

function assertLiveKey() {
  if (!process.env.ANTHROPIC_API_KEY) {
    throw new Error("ANTHROPIC_API_KEY is required for ORCH-07 live cache smoke");
  }
}

function run(command, args, env) {
  const printable = [command, ...args].join(" ");
  console.log(`[ratchet-live-uat] $ ${printable}`);
  const childEnv = { ...env };
  for (const [key, value] of Object.entries(childEnv)) {
    if (value === undefined) delete childEnv[key];
  }
  const result = spawnSync(command, args, {
    cwd: ADMIN_ROOT,
    env: childEnv,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${printable} exited ${result.status}`);
}

function listFiles(root) {
  if (!fs.existsSync(root)) return [];
  const out = [];
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(abs);
      } else if (entry.isFile()) {
        out.push(path.relative(root, abs).split(path.sep).join("/"));
      }
    }
  }
  return out.sort();
}

function readNdjson(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const text = fs.readFileSync(filePath, "utf8").trim();
  if (!text) return [];
  return text.split("\n").map((line, index) => {
    try {
      return JSON.parse(line);
    } catch (err) {
      throw new Error(`${path.relative(ADMIN_ROOT, filePath)}:${index + 1} is malformed JSON: ${err.message}`);
    }
  });
}

function identityList(rows) {
  const set = new Set();
  for (const row of rows) {
    if (!row || typeof row.claim_key !== "string" || typeof row.finding_id !== "string") {
      throw new Error("Candidate row missing claim_key/finding_id identity");
    }
    set.add(`${row.claim_key}\t${row.finding_id}`);
  }
  return Array.from(set).sort();
}

function sameStringList(left, right) {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}

function numberOrZero(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function summaryPath() {
  return path.join(PROOF_ROOT, "summary.json");
}

function writeSummary(value) {
  fs.mkdirSync(PROOF_ROOT, { recursive: true });
  fs.writeFileSync(summaryPath(), JSON.stringify(value, null, 2) + "\n");
}

function runSelfTest() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-live-uat-"));
  try {
    const root = path.join(tmp, "admin-visuals");
    for (const project of PROJECTS) {
      fs.mkdirSync(path.join(root, project), { recursive: true });
      for (const file of CAPTURE_FILES) {
        fs.writeFileSync(path.join(root, project, file), file.endsWith(".json") ? "{}\n" : "png");
      }
    }
    const capture = assertDashboardCapture(root);
    assertSelf("capture assertion accepts exact dashboard matrix", capture.actual_artifacts.length === 8);

    fs.writeFileSync(path.join(root, "chromium-desktop", "subscriptions.png"), "png");
    let extraFailed = false;
    try {
      assertDashboardCapture(root);
    } catch {
      extraFailed = true;
    }
    assertSelf("capture assertion rejects non-dashboard artifact", extraFailed);

    const idsA = identityList([
      { claim_key: "a", finding_id: "f-0000000000000001" },
      { claim_key: "a", finding_id: "f-0000000000000001" },
      { claim_key: "b", finding_id: "f-0000000000000002" },
    ]);
    const idsB = identityList([
      { claim_key: "b", finding_id: "f-0000000000000002" },
      { claim_key: "a", finding_id: "f-0000000000000001" },
    ]);
    assertSelf("identity comparison is order-insensitive and unique", sameStringList(idsA, idsB));

    console.log("ratchet-live-uat self-test passed.");
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

function assertSelf(name, condition) {
  if (!condition) throw new Error(`Self-test failed: ${name}`);
  console.log(`self-test pass: ${name}`);
}
