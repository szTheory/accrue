#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";

const INCIDENT_TITLE = "[provider-proof] recurring Stripe proof unhealthy";
const RELEVANT_PATHS = [
  /^\.github\/workflows\/ci\.yml$/,
  /^accrue\/config\/runtime\.exs$/,
  /^accrue\/test\/live_stripe\//,
  /^accrue\/test\/accrue\/runtime_config_test\.exs$/,
  /^scripts\/ci\/(?:bootstrap_stripe_provider_proof|provider_proof|render_provider_summary|stripe_test_fixtures|verify_provider_proof|verify_stripe_test_fixtures|verify_stripe_webhook_boot_evidence|provider_proof_automation)\.mjs$/,
];

function fail(message) {
  throw new Error(message);
}

export function classifyTrigger(eventName, changedFiles = []) {
  if (eventName === "schedule") return { should_run: true, trigger_class: "scheduled" };
  if (eventName === "workflow_dispatch") return { should_run: true, trigger_class: "manual" };
  if (eventName === "push") {
    const shouldRun = changedFiles.some((file) => RELEVANT_PATHS.some((pattern) => pattern.test(file)));
    return { should_run: shouldRun, trigger_class: shouldRun ? "repair" : "irrelevant" };
  }
  return { should_run: false, trigger_class: "unsupported" };
}

function runCommand(command, args) {
  const result = spawnSync(command, args, { encoding: "utf8", env: process.env });
  if (result.status !== 0) fail(`${command} ${args[0] || ""} failed: ${String(result.stderr || result.stdout).trim()}`);
  return String(result.stdout || "").trim();
}

function changedFilesForPush(before, sha, run = runCommand) {
  if (!/^[0-9a-f]{40}$/.test(sha || "")) fail("--sha must be a full commit SHA");
  if (/^0{40}$/.test(before || "")) return run("git", ["show", "--pretty=", "--name-only", sha]).split("\n").filter(Boolean);
  if (!/^[0-9a-f]{40}$/.test(before || "")) fail("--before must be a full commit SHA");
  return run("git", ["diff", "--name-only", before, sha]).split("\n").filter(Boolean);
}

function sanitizeRecord(record, runUrl) {
  const proofState = typeof record?.proof_state === "string" ? record.proof_state : "misconfigured";
  const reasonCode = typeof record?.reason_code === "string" ? record.reason_code : "artifact_missing";
  if (!/^[a-z_]+$/.test(proofState) || !/^[a-z_]+$/.test(reasonCode)) fail("provider proof classification is not sanitized");
  const count = (value) => Number.isInteger(value) && value >= 0 ? value : 0;
  return {
    proof_state: proofState,
    reason_code: reasonCode,
    sha: typeof record?.sha === "string" && /^[0-9a-f]{7,64}$/.test(record.sha) ? record.sha : "unknown",
    selected_count: count(record?.selected_count),
    passed_count: count(record?.passed_count),
    skipped_count: count(record?.skipped_count),
    run_url: /^https:\/\/github\.com\/[^\s]+\/actions\/runs\/\d+$/.test(runUrl || "") ? runUrl : null,
  };
}

function issueBody(summary) {
  return [
    "The recurring Stripe provider proof is unhealthy.",
    "",
    `- proof_state: \`${summary.proof_state}\``,
    `- reason_code: \`${summary.reason_code}\``,
    `- sha: \`${summary.sha}\``,
    `- selected/passed/skipped: \`${summary.selected_count}/${summary.passed_count}/${summary.skipped_count}\``,
    summary.run_url ? `- run: ${summary.run_url}` : "- run: unavailable",
    "",
    "This issue is updated in place and closes automatically after a proved run. No credential values or raw provider logs are included.",
  ].join("\n");
}

export function reconcileIssue({ record, repository, runUrl, run = runCommand }) {
  if (!/^[^/\s]+\/[^/\s]+$/.test(repository || "")) fail("--repo must be owner/repository");
  run("gh", ["label", "create", "provider-proof", "--repo", repository, "--color", "B60205", "--description", "Recurring provider-proof health", "--force"]);
  const issues = JSON.parse(run("gh", ["issue", "list", "--repo", repository, "--state", "all", "--label", "provider-proof", "--limit", "100", "--json", "number,title,state"]));
  const existing = issues.find((issue) => issue.title === INCIDENT_TITLE);
  const summary = sanitizeRecord(record, runUrl);
  if (summary.proof_state === "proved") {
    if (existing?.state === "OPEN") {
      run("gh", ["issue", "close", String(existing.number), "--repo", repository, "--comment", `Recovered with proved provider evidence at ${summary.sha}${summary.run_url ? ` (${summary.run_url})` : ""}.`]);
      return { action: "closed", number: existing.number };
    }
    return { action: "none" };
  }

  const body = issueBody(summary);
  if (!existing) {
    const url = run("gh", ["issue", "create", "--repo", repository, "--label", "provider-proof", "--title", INCIDENT_TITLE, "--body", body]);
    return { action: "created", url };
  }
  if (existing.state !== "OPEN") run("gh", ["issue", "reopen", String(existing.number), "--repo", repository]);
  run("gh", ["issue", "comment", String(existing.number), "--repo", repository, "--body", body]);
  return { action: existing.state === "OPEN" ? "updated" : "reopened", number: existing.number };
}

function selfTest() {
  assert.deepEqual(classifyTrigger("schedule"), { should_run: true, trigger_class: "scheduled" });
  assert.deepEqual(classifyTrigger("workflow_dispatch"), { should_run: true, trigger_class: "manual" });
  assert.deepEqual(classifyTrigger("push", ["README.md"]), { should_run: false, trigger_class: "irrelevant" });
  assert.deepEqual(classifyTrigger("push", ["accrue/config/runtime.exs"]), { should_run: true, trigger_class: "repair" });
  assert.deepEqual(classifyTrigger("push", ["scripts/ci/bootstrap_stripe_provider_proof.mjs"]), { should_run: true, trigger_class: "repair" });

  const calls = [];
  const unhealthyRun = (_command, args) => {
    calls.push(args);
    if (args[0] === "issue" && args[1] === "list") return "[]";
    if (args[0] === "issue" && args[1] === "create") return "https://github.com/szTheory/accrue/issues/1";
    return "";
  };
  assert.equal(reconcileIssue({ record: { proof_state: "failed", reason_code: "selected_assertions_failed", sha: "a".repeat(40), selected_count: 2, passed_count: 1 }, repository: "szTheory/accrue", runUrl: "https://github.com/szTheory/accrue/actions/runs/1", run: unhealthyRun }).action, "created");
  const serialized = JSON.stringify(calls);
  assert.doesNotMatch(serialized, /whsec_|sk_(?:test|live)_/, "incident commands contain no credential material");

  const recoveryCalls = [];
  const recoveryRun = (_command, args) => {
    recoveryCalls.push(args);
    if (args[0] === "issue" && args[1] === "list") return JSON.stringify([{ number: 7, title: INCIDENT_TITLE, state: "OPEN" }]);
    return "";
  };
  assert.equal(reconcileIssue({ record: { proof_state: "proved", reason_code: "complete_provider_evidence", sha: "b".repeat(40) }, repository: "szTheory/accrue", run: recoveryRun }).action, "closed");
  assert.equal(recoveryCalls.filter((args) => args[0] === "issue" && args[1] === "close").length, 1);
  console.log("provider proof automation self-test: PASS");
}

function parseArgs(args) {
  const values = {};
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (["--self-test", "--classify-trigger", "--reconcile-issue"].includes(arg)) values[arg.slice(2)] = true;
    else values[arg.slice(2)] = args[++index];
  }
  return values;
}

function main() {
  const values = parseArgs(process.argv.slice(2));
  if (values["self-test"]) return selfTest();
  if (values["classify-trigger"]) {
    const files = values.event === "push" ? changedFilesForPush(values.before, values.sha) : [];
    const result = classifyTrigger(values.event, files);
    const output = `should_run=${result.should_run}\ntrigger_class=${result.trigger_class}\n`;
    if (values.output) fs.appendFileSync(values.output, output);
    else process.stdout.write(output);
    return;
  }
  if (values["reconcile-issue"]) {
    let record;
    try {
      record = JSON.parse(fs.readFileSync(values.record, "utf8"));
    } catch (_error) {
      record = { proof_state: "misconfigured", reason_code: "artifact_missing", sha: values.sha || "unknown" };
    }
    const result = reconcileIssue({ record, repository: values.repo, runUrl: values["run-url"] });
    console.log(`provider proof incident reconciliation: ${result.action}`);
    return;
  }
  fail("use --self-test, --classify-trigger, or --reconcile-issue");
}

try {
  main();
} catch (error) {
  console.error(`provider proof automation: FAIL: ${error.message}`);
  process.exitCode = 1;
}
