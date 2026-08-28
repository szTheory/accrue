#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export const REQUIRED_ACTIONS_SECRETS = [
  "STRIPE_TEST_SECRET_KEY",
  "STRIPE_WEBHOOK_SECRET",
  "ACCRUE_LIVE_BASIC_PRICE",
  "ACCRUE_LIVE_PRO_PRICE",
];

function fail(message) {
  throw new Error(message);
}

export function validateSigningSecret(value) {
  if (typeof value !== "string" || !/^whsec_[A-Za-z0-9_\-]{12,}$/.test(value)) {
    fail("stdin must contain one Stripe endpoint signing secret beginning with whsec_");
  }
  if (/\s/.test(value)) fail("signing secret must not contain whitespace");
  return value;
}

function parseArgs(args) {
  const values = {};
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === "--self-test" || arg === "--authorize-one-proof") values[arg.slice(2)] = true;
    else if (arg === "--repo" || arg === "--ref" || arg === "--evidence-out") values[arg.slice(2)] = args[++index];
    else fail(`unexpected argument: ${arg}`);
  }
  return values;
}

function commandRunner(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    encoding: "utf8",
    input: options.input,
    env: process.env,
    stdio: options.capture === false ? [options.input == null ? "inherit" : "pipe", "inherit", "inherit"] : "pipe",
  });
  if (result.status !== 0) {
    const detail = String(result.stderr || result.stdout || "command failed").trim();
    fail(`${command} ${args[0] || ""} failed: ${detail}`);
  }
  return String(result.stdout || "").trim();
}

function assertSecretInventory(source, required = REQUIRED_ACTIONS_SECRETS) {
  let inventory;
  try {
    inventory = JSON.parse(source);
  } catch (_error) {
    fail("GitHub secret inventory was not valid JSON");
  }
  const names = new Set(inventory.map((entry) => entry.name));
  const missing = required.filter((name) => !names.has(name));
  if (missing.length > 0) fail(`required GitHub Actions secret names are missing: ${missing.join(", ")}`);
  return inventory
    .filter((entry) => REQUIRED_ACTIONS_SECRETS.includes(entry.name))
    .map(({ name, updatedAt }) => ({ name, updated_at: updatedAt || null }));
}

function waitForDispatchedRun({ repo, sha, dispatchAt, run, sleep }) {
  for (let attempt = 0; attempt < 25; attempt += 1) {
    const source = run("gh", [
      "run", "list", "--repo", repo, "--workflow", "ci.yml", "--event", "workflow_dispatch", "--limit", "50",
      "--json", "databaseId,headSha,createdAt,url,event,workflowName,attempt",
    ]);
    let runs;
    try {
      runs = JSON.parse(source);
    } catch (_error) {
      fail("GitHub workflow run inventory was not valid JSON");
    }
    const matches = runs.filter((candidate) =>
      candidate.headSha === sha &&
      candidate.event === "workflow_dispatch" &&
      candidate.workflowName === "CI" &&
      Date.parse(candidate.createdAt) >= Date.parse(dispatchAt)
    );
    if (matches.length > 1) fail("multiple workflow runs matched the one-dispatch authority");
    if (matches.length === 1) {
      const match = matches[0];
      if (!Number.isInteger(match.databaseId) || match.databaseId <= 0 || match.attempt !== 1) {
        fail("the authorized workflow run does not have an immutable attempt-1 identity");
      }
      if (match.url !== `https://github.com/${repo}/actions/runs/${match.databaseId}`) {
        fail("the authorized workflow run URL does not match its immutable identity");
      }
      return match;
    }
    if (attempt < 24) sleep(2_000);
  }
  fail("the authorized dispatch did not produce an observable CI run within 48 seconds");
}

export function executeBootstrap({
  repo,
  ref,
  signingSecret,
  evidenceOut,
  run = commandRunner,
  now = () => new Date().toISOString(),
  sleep = (milliseconds) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds),
}) {
  if (!repo || !/^[^/\s]+\/[^/\s]+$/.test(repo)) fail("--repo must be owner/repository");
  if (!ref || !/^[A-Za-z0-9][A-Za-z0-9._\/-]*$/.test(ref) || /^[0-9a-f]{40}$/.test(ref) || ref.includes("..") || ref.includes("@{")) {
    fail("--ref must be a named branch or tag, not a raw SHA");
  }
  if (evidenceOut) {
    if (fs.existsSync(evidenceOut)) fail("--evidence-out already exists; refusing to overwrite dispatch authority");
    try {
      fs.accessSync(path.dirname(path.resolve(evidenceOut)), fs.constants.W_OK);
    } catch (_error) {
      fail("--evidence-out parent directory is not writable");
    }
  }
  const secret = validateSigningSecret(signingSecret);

  run("gh", ["auth", "status", "--hostname", "github.com"]);
  run("node", ["scripts/ci/verify_provider_proof.mjs", "--fixtures"]);
  run("node", ["scripts/ci/verify_stripe_webhook_boot_evidence.mjs", "--fixtures"]);
  run("mix", ["test", "test/accrue/runtime_config_test.exs", "test/accrue/config_test.exs"], { cwd: "accrue" });

  const repairedSha = run("git", ["rev-parse", `${ref}^{commit}`]);
  if (!/^[0-9a-f]{40}$/.test(repairedSha)) fail("--ref did not resolve to a full commit SHA");
  const remoteSha = run("gh", ["api", `repos/${repo}/commits/${encodeURIComponent(ref)}`, "--jq", ".sha"]);
  if (remoteSha !== repairedSha) fail("the pushed named ref does not resolve to the local repaired commit");

  const beforeInventory = run("gh", ["secret", "list", "--app", "actions", "--repo", repo, "--json", "name,updatedAt"]);
  assertSecretInventory(beforeInventory, REQUIRED_ACTIONS_SECRETS.filter((name) => name !== "STRIPE_WEBHOOK_SECRET"));
  run("gh", ["secret", "set", "STRIPE_WEBHOOK_SECRET", "--app", "actions", "--repo", repo], { input: `${secret}\n` });
  const inventory = assertSecretInventory(
    run("gh", ["secret", "list", "--app", "actions", "--repo", repo, "--json", "name,updatedAt"]),
  );

  const dispatchAt = now();
  run("gh", ["workflow", "run", "ci.yml", "--repo", repo, "--ref", ref, "-f", "run_live_stripe=true"]);
  const workflowRun = waitForDispatchedRun({ repo, sha: repairedSha, dispatchAt, run, sleep });
  const observedAt = now();
  const evidence = {
    schema_version: 1,
    repository: repo,
    ref,
    repaired_sha: repairedSha,
    dispatch_at: dispatchAt,
    observed_at: observedAt,
    workflow: "CI",
    event: "workflow_dispatch",
    input_run_live_stripe: true,
    run_id: workflowRun.databaseId,
    run_url: workflowRun.url,
    run_attempt: workflowRun.attempt,
    run_created_at: workflowRun.createdAt,
    attempt_ceiling: 1,
    retry_authorized: false,
    secret_names: inventory,
  };
  if (evidenceOut) fs.writeFileSync(evidenceOut, `${JSON.stringify(evidence, null, 2)}\n`, { mode: 0o600, flag: "wx" });
  return evidence;
}

function selfTest() {
  const secret = "whsec_fixture_1234567890";
  const calls = [];
  const run = (command, args, options = {}) => {
    calls.push({ command, args, input: options.input });
    if (command === "git" || args[0] === "api") return "a".repeat(40);
    if (args[0] === "run" && args[1] === "list") {
      return JSON.stringify([{ databaseId: 123, headSha: "a".repeat(40), createdAt: "2026-08-28T12:00:00.000Z", url: "https://github.com/szTheory/accrue/actions/runs/123", event: "workflow_dispatch", workflowName: "CI", attempt: 1 }]);
    }
    if (args[0] === "secret" && args[1] === "list") return JSON.stringify(REQUIRED_ACTIONS_SECRETS.map((name) => ({ name, updatedAt: "2026-08-28T00:00:00Z" })));
    return "";
  };
  const times = ["2026-08-28T12:00:00.000Z", "2026-08-28T12:00:01.000Z"];
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-stripe-bootstrap-"));
  const evidenceOut = path.join(temp, "evidence.json");
  const evidence = executeBootstrap({ repo: "szTheory/accrue", ref: "main", signingSecret: secret, evidenceOut, run, now: () => times.shift(), sleep: () => {} });
  assert.equal(calls.filter(({ args }) => args[0] === "workflow" && args[1] === "run").length, 1, "bootstrap dispatches exactly once");
  const secretSet = calls.find(({ args }) => args[0] === "secret" && args[1] === "set");
  assert.equal(secretSet.input, `${secret}\n`, "secret travels only over stdin");
  assert.ok(!JSON.stringify(calls.map(({ args }) => args)).includes(secret), "secret is absent from command arguments");
  assert.ok(!JSON.stringify(evidence).includes(secret), "secret is absent from evidence");
  assert.equal(evidence.attempt_ceiling, 1);
  assert.equal(evidence.retry_authorized, false);
  assert.equal(evidence.run_id, 123);
  assert.equal(evidence.run_attempt, 1);
  assert.match(evidence.run_url, /\/actions\/runs\/123$/);
  assert.ok(!fs.readFileSync(evidenceOut, "utf8").includes(secret), "persisted evidence contains no secret");
  assert.equal(fs.statSync(evidenceOut).mode & 0o777, 0o600, "evidence is owner-readable only");
  assert.throws(() => validateSigningSecret("sk_test_wrong_kind"), /whsec_/);
  assert.throws(() => executeBootstrap({ repo: "szTheory/accrue", ref: "a".repeat(40), signingSecret: secret, run }), /named branch or tag/);
  assert.throws(
    () => executeBootstrap({ repo: "szTheory/accrue", ref: "main", signingSecret: secret, run: (command, args) => args[0] === "secret" && args[1] === "list" ? "[]" : command === "git" || args[0] === "api" ? "a".repeat(40) : "" }),
    /secret names are missing/,
  );
  fs.rmSync(temp, { recursive: true, force: true });
  console.log("Stripe provider bootstrap self-test: PASS");
}

function main() {
  const values = parseArgs(process.argv.slice(2));
  if (values["self-test"]) return selfTest();
  if (!values["authorize-one-proof"]) fail("--authorize-one-proof is required because dispatch creates immutable evidence");
  if (!values["evidence-out"]) fail("--evidence-out is required so the unique dispatch can be reconciled automatically");
  if (process.stdin.isTTY) fail("pipe the endpoint secret over stdin; interactive secret entry is intentionally unsupported");
  const signingSecret = fs.readFileSync(0, "utf8").trim();
  const evidence = executeBootstrap({ repo: values.repo, ref: values.ref, signingSecret, evidenceOut: values["evidence-out"] });
  process.stdout.write(`Stripe provider bootstrap dispatched one proof for ${evidence.repaired_sha}; no secret value was logged.\n`);
}

try {
  main();
} catch (error) {
  console.error(`Stripe provider bootstrap: FAIL: ${error.message}`);
  process.exitCode = 1;
}
