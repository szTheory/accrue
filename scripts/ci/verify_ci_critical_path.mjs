#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const phase = path.join(root, ".planning/phases/227-measured-critical-path-improvement");
const frozenRoot = path.join(root, ".planning/phases/226-ci-baseline-proof-semantics");
const oldHostNeeds = "needs: [admin-drift-docs, docs-contracts-shift-left]";
const newHostNeeds = "needs: [docs-contracts-shift-left]";

const digest = (value) => crypto.createHash("sha256").update(value).digest("hex");
const readJson = (file) => JSON.parse(fs.readFileSync(file, "utf8"));
const fail = (message) => { throw new Error(`critical-path contract: ${message}`); };

function jobBlock(source, id) {
  const match = source.match(new RegExp(`^  ${id}:\\n([\\s\\S]*?)(?=^  [A-Za-z0-9_-]+:|\\z)`, "m"));
  if (!match) fail(`missing job ${id}`);
  return match[0];
}

function needsFor(source, id) {
  const block = jobBlock(source, id);
  const inline = block.match(/^    needs: \[([^\]]*)\]$/m);
  if (inline) return inline[1].split(",").map((item) => item.trim()).filter(Boolean);
  const multiline = block.match(/^    needs:\n\s*\[([\s\S]*?)\]\n/m);
  if (!multiline) return [];
  return [...multiline[1].matchAll(/([A-Za-z0-9_-]+),/g)].map((entry) => entry[1]);
}

function normalizedWorkflow(source) {
  const host = jobBlock(source, "host-integration");
  if (!host.includes(newHostNeeds) && !host.includes(oldHostNeeds)) fail("host-integration needs declaration is missing");
  return source.replace(host, host.replace(newHostNeeds, oldHostNeeds));
}

function verifyFrozenInputs(contract) {
  for (const [relative, expected] of Object.entries(contract.frozen_inputs)) {
    const actual = digest(fs.readFileSync(path.join(frozenRoot, relative)));
    assert.equal(actual, expected, `frozen input digest changed: ${relative}`);
  }
}

export function verifyWorkflowContract(workflowSource, contract) {
  verifyFrozenInputs(contract);
  assert.equal(digest(normalizedWorkflow(workflowSource)), contract.workflow_sha256, "workflow changed outside the one permitted host prerequisite deletion");
  for (const [id, expected] of Object.entries(contract.jobs)) {
    const block = jobBlock(workflowSource, id);
    assert.match(block, new RegExp(`^    name: ${expected.name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "m"), `job display name changed: ${id}`);
    const actualNeeds = needsFor(workflowSource, id);
    const allowedNeeds = id === "host-integration" && workflowSource.includes(oldHostNeeds)
      ? contract.inverse_rollback.host_integration_needs
      : expected.needs;
    assert.deepEqual(actualNeeds, allowedNeeds, `needs changed: ${id}`);
  }
  for (const artifact of contract.artifacts) {
    assert.match(workflowSource, new RegExp(`uses: actions/upload-artifact@v7[\\s\\S]{0,360}name: ${artifact.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`), `artifact changed or removed: ${artifact}`);
  }
  assert.match(workflowSource, /compatibility: 'Floor'[\s\S]*?support: 'required'/, "Floor required release cell changed");
  assert.match(workflowSource, /compatibility: 'Primary dev target'[\s\S]*?sigra: 'on'[\s\S]*?support: 'advisory'/, "Sigra advisory release cell changed");
  assert.match(workflowSource, /compatibility: 'Primary dev target'[\s\S]*?opentelemetry: 'on'[\s\S]*?support: 'required'/, "OpenTelemetry required release cell changed");
  return { state: jobBlock(workflowSource, "host-integration").includes(newHostNeeds) ? "candidate" : "inverse_rollback" };
}

function eligible(record, contract, context) {
  return record.repository === context.expectedRepository && record.sha && record.run_attempt === 1 &&
    ["pull_request", "push", "workflow_dispatch"].includes(record.event_class) &&
    record.conclusion === "success" && record.fingerprint === context.fingerprint && Number.isFinite(record.duration_seconds);
}

export function verifyComparisonEvidence(records, contract, validationContext = {}) {
  const context = { expectedRepository: validationContext.expectedRepository || "szTheory/accrue", fingerprint: validationContext.fingerprint || "phase-227-candidate" };
  const accepted = records.filter((record) => eligible(record, contract, context));
  assert.ok(accepted.length >= 3, "fewer than three eligible first-attempt observations");
  assert.equal(new Set(accepted.map((record) => record.event_class)).size, 1, "eligible observations must use one event class");
  const durations = accepted.map((record) => record.duration_seconds).sort((a, b) => a - b);
  const median = durations[Math.floor(durations.length / 2)];
  assert.ok(median <= contract.thresholds.keep_median_seconds, `median ${median}s exceeds keep threshold`);
  for (const record of accepted) {
    assert.ok(record.duration_seconds <= contract.thresholds.maximum_observation_seconds || record.external_anomaly === true, "unsubstantiated observation exceeds Phase 226 p95");
  }
  assert.ok(records.some((record) => record.aggregate_failure === true && record.host_browser_completed === true && record.artifacts_retained === true), "negative control must retain independent host/browser completion and aggregate failure");
  return { keep: true, median_seconds: median, observations: accepted.length };
}

export function renderCriticalPathComparison(records, contract, validationContext = {}) {
  const result = verifyComparisonEvidence(records, contract, validationContext);
  return `# Phase 227 critical-path comparison\n\n- keep: ${result.keep}\n- eligible observations: ${result.observations}\n- median: ${result.median_seconds}s\n`;
}

export function verifyFixtures() {
  const contract = readJson(path.join(phase, "227-ci-contract.json"));
  const fixtures = readJson(path.join(phase, "fixtures/ci-critical-path-cases.json"));
  const current = fs.readFileSync(path.join(root, ".github/workflows/ci.yml"), "utf8");
  const host = jobBlock(current, "host-integration");
  const candidate = current.replace(host, host.replace(oldHostNeeds, newHostNeeds));
  const rollback = current.replace(host, host.replace(newHostNeeds, oldHostNeeds));
  assert.equal(verifyWorkflowContract(candidate, contract).state, "candidate", "intended graph passes");
  assert.equal(verifyWorkflowContract(rollback, contract).state, "inverse_rollback", "inverse graph remains explicit");
  assert.throws(() => verifyWorkflowContract(candidate.replace("Host integration (required deterministic gate)", "renamed"), contract), /workflow changed/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("accrue-host-server-log", "changed-artifact"), contract), /workflow changed/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("playwright-e2e,", ""), contract), /workflow changed/);
  assert.deepEqual(verifyComparisonEvidence(fixtures.accepted_evidence, contract, fixtures.context), { keep: true, median_seconds: 1600, observations: 3 });
  for (const negative of fixtures.rejected_evidence) assert.throws(() => verifyComparisonEvidence(negative, contract, fixtures.context));
  return true;
}

function option(name) { const index = process.argv.indexOf(name); return index >= 0 ? process.argv[index + 1] : null; }

const forbiddenEvidenceFields = /(?:actor|branch|token|secret|log|payload|artifact_content|user_data)/i;
const stableJob = (name) => String(name).toLowerCase().replace(/\([^)]*\)/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const api = (endpoint) => JSON.parse(execFileSync("gh", ["api", "-H", "Accept: application/vnd.github+json", endpoint], { encoding: "utf8" }));
const immutableRunUrl = (repository, runId) => `https://github.com/${repository}/actions/runs/${runId}`;
const immutableJobUrl = (repository, runId, jobId) => `${immutableRunUrl(repository, runId)}/job/${jobId}`;
const apiErrorStatus = (endpoint) => spawnSync("gh", ["api", endpoint], { encoding: "utf8" }).status;

function evidenceRecords(file) {
  if (!file || !fs.existsSync(file)) fail("--evidence must name an existing NDJSON file");
  const records = fs.readFileSync(file, "utf8").trim().split("\n").filter(Boolean).map((line, index) => {
    let record;
    try { record = JSON.parse(line); } catch { fail(`evidence line ${index + 1} is not JSON`); }
    if (!record || Array.isArray(record) || typeof record !== "object") fail(`evidence line ${index + 1} is not an object`);
    for (const key of Object.keys(record)) if (forbiddenEvidenceFields.test(key)) fail(`evidence line ${index + 1} contains forbidden field ${key}`);
    return record;
  });
  if (!records.length) fail("evidence must not be empty");
  return records;
}

function requireRecordUrl(record, key, expected) {
  if (record[key] !== expected) fail(`${record.kind}.${key} is not repository-bound`);
}

function workflowRevision(repository, sha) {
  const response = api(`repos/${repository}/contents/.github/workflows/ci.yml?ref=${sha}`);
  if (typeof response.content !== "string" || response.encoding !== "base64") fail("live workflow source is unavailable");
  return `sha256:${digest(Buffer.from(response.content.replace(/\n/g, ""), "base64"))}`;
}

function liveInventory(repository, record) {
  const run = api(`repos/${repository}/actions/runs/${record.run_id}`);
  if (run.head_sha !== record.sha || run.run_attempt !== record.run_attempt || run.event !== record.event_class || run.conclusion !== record.conclusion) fail(`live run facts differ for ${record.run_id}`);
  requireRecordUrl(record, "run_url", immutableRunUrl(repository, record.run_id));
  const revision = workflowRevision(repository, record.sha);
  if (revision !== record.workflow_revision) fail(`workflow revision differs for ${record.run_id}`);
  const jobs = api(`repos/${repository}/actions/runs/${record.run_id}/attempts/${record.run_attempt}/jobs?filter=all`).jobs;
  if (!Array.isArray(jobs)) fail(`live jobs are unavailable for ${record.run_id}`);
  const byIdentity = new Map(jobs.map((job) => [stableJob(job.name), job]));
  for (const identity of ["release-gate", "docs-and-bash-contracts-shift-left", "host-integration", "playwright-e2e", "annotation-sweep"]) {
    if (!jobs.some((job) => stableJob(job.name) === identity || (identity === "playwright-e2e" && stableJob(job.name).startsWith("playwright-e2e-shard")))) fail(`required live job missing: ${identity}`);
  }
  const release = jobs.find((job) => stableJob(job.name) === "release-gate");
  const docs = jobs.find((job) => stableJob(job.name) === "docs-and-bash-contracts-shift-left");
  const host = jobs.find((job) => stableJob(job.name) === "host-integration");
  const shards = jobs.filter((job) => stableJob(job.name).startsWith("playwright-e2e-shard"));
  const annotation = jobs.find((job) => stableJob(job.name) === "annotation-sweep");
  if (![release, docs, host, annotation].every(Boolean) || !shards.length) fail(`required timing jobs are incomplete for ${record.run_id}`);
  const latestShard = Math.max(...shards.map((job) => Date.parse(job.completed_at)));
  const duration = Math.round((latestShard - Date.parse(release.started_at)) / 1000);
  const hostWait = Math.round((Date.parse(host.started_at) - Date.parse(docs.completed_at)) / 1000);
  if (duration !== record.duration_seconds || hostWait !== record.host_dag_wait_seconds) fail(`derived timing differs for ${record.run_id}`);
  if (record.job_urls?.release_gate !== immutableJobUrl(repository, record.run_id, release.id) || record.job_urls?.host_integration !== immutableJobUrl(repository, record.run_id, host.id) || record.job_urls?.annotation_sweep !== immutableJobUrl(repository, record.run_id, annotation.id)) fail(`job URLs differ for ${record.run_id}`);
  const artifacts = api(`repos/${repository}/actions/runs/${record.run_id}/artifacts?per_page=100`).artifacts;
  if (!Array.isArray(artifacts)) fail(`artifact inventory is unavailable for ${record.run_id}`);
  const names = new Set(artifacts.map((artifact) => artifact.name));
  for (const name of readJson(path.join(phase, "227-ci-contract.json")).artifacts) {
    if (record.artifacts?.[name] !== names.has(name)) fail(`artifact inventory differs for ${record.run_id}: ${name}`);
  }
  return { run, jobs, annotation, host, shards };
}

function verifyLiveEvidence(records, contract, repository, requireNegative, branch) {
  if (!repository || repository !== "szTheory/accrue") fail("--expected-repository must be szTheory/accrue for live verification");
  const comparisons = records.filter((record) => record.kind === "comparison");
  if (comparisons.length !== 1 || comparisons[0].before_median_seconds !== 2083 || comparisons[0].threshold_seconds !== contract.thresholds.keep_median_seconds) fail("comparison record is missing frozen Phase 226 facts");
  const post = records.filter((record) => record.kind === "post_run");
  if (post.length !== 3) fail("evidence must retain exactly three post_run records");
  for (const record of post) {
    if (record.repository !== repository || record.run_attempt !== 1 || record.conclusion !== "success" || record.fingerprint !== "phase-227-candidate") fail(`post_run is ineligible: ${record.run_id}`);
    liveInventory(repository, record);
  }
  assert.equal(new Set(post.map((record) => record.sha)).size, 1, "candidate observations must use one exact SHA");
  assert.equal(new Set(post.map((record) => record.event_class)).size, 1, "candidate observations must use one event class");
  if (requireNegative) {
    const controls = records.filter((record) => record.kind === "negative_control");
    if (controls.length !== 1) fail("evidence must contain one negative_control record");
    const control = controls[0];
    const { annotation, host, shards } = liveInventory(repository, control);
    if (annotation.conclusion !== "failure" || host.conclusion !== "success" || !shards.every((job) => job.conclusion === "success")) fail("negative control did not preserve host/browser completion and aggregate failure");
    const annotations = api(`repos/${repository}/check-runs/${control.job_ids.docs}/annotations?per_page=100`);
    if (!Array.isArray(annotations) || !annotations.some((item) => item.annotation_level === "failure" && item.title === control.annotation_marker)) fail("controlled annotation marker is absent");
    if (!branch || apiErrorStatus(`repos/${repository}/git/ref/heads/${branch}`) === 0) fail("temporary control branch still exists or --control-branch is missing");
  }
  if (!records.some((record) => record.kind === "decision_pending" && record.state === "decision_pending")) fail("evidence must retain decision_pending state");
  return true;
}

export function renderCriticalPathEvidence(records) {
  const comparison = records.find((record) => record.kind === "comparison");
  const post = records.filter((record) => record.kind === "post_run").sort((a, b) => a.run_id - b.run_id);
  const control = records.find((record) => record.kind === "negative_control");
  const pending = records.find((record) => record.kind === "decision_pending");
  const durations = post.map((record) => record.duration_seconds).sort((a, b) => a - b);
  const median = durations[Math.floor(durations.length / 2)];
  const range = `${durations[0]}-${durations.at(-1)}s`;
  return `# Phase 227 critical-path comparison\n\n## Current fact\n\n- Frozen Phase 226 median: ${comparison.before_median_seconds}s; p95: ${comparison.before_p95_seconds}s\n- Candidate median: ${median}s; range: ${range}; keep threshold: ${comparison.threshold_seconds}s\n- Event class: ${post[0].event_class}; samples: ${post.length}; fingerprint: ${post[0].fingerprint}\n\n## Decision\n\n- state: \`${pending.state}\`\n- owner: ${pending.owner}\n- next command: \`${pending.next_command}\`\n\n## Immutable observations\n\n| Run | Staged duration | Removed host DAG wait | Workflow context |\n| --- | ---: | ---: | --- |\n${post.map((record) => `| [${record.run_id}](${record.run_url}) | ${record.duration_seconds}s | ${record.host_dag_wait_seconds}s | ${record.workflow_duration_seconds}s |`).join("\n")}\n\n## Controlled negative control\n\n- [run](${control.run_url}) — marker \`${control.annotation_marker}\`; annotation sweep: failure; host/browser: complete.\n- Temporary control branch was removed after live verification; artifact presence/absence is retained in NDJSON.\n\n## Evidence boundary\n\nPhase 226 inputs remain frozen; this report is rendered deterministically from \`227-CI-CRITICAL-PATH.ndjson\`.\n`;
}

if (process.argv.includes("--fixtures")) verifyFixtures();
const workflow = option("--workflow");
const contractFile = option("--contract") || path.join(phase, "227-ci-contract.json");
if (workflow) verifyWorkflowContract(fs.readFileSync(workflow, "utf8"), readJson(contractFile));
if (process.argv.includes("--require-kept")) {
  const evidence = option("--evidence");
  if (!evidence) fail("--require-kept needs --evidence");
  const records = evidenceRecords(evidence);
  const result = verifyComparisonEvidence(records, readJson(contractFile), { expectedRepository: option("--expected-repository") });
  if (!result.keep) fail("evidence is rolled back");
}
if (process.argv.includes("--render-evidence")) {
  const evidence = option("--evidence");
  const rendered = option("--rendered");
  if (!rendered) fail("--render-evidence needs --rendered");
  fs.writeFileSync(rendered, renderCriticalPathEvidence(evidenceRecords(evidence)));
}
if (process.argv.includes("--verify-live-actions")) {
  const evidence = option("--evidence");
  const records = evidenceRecords(evidence);
  const contract = readJson(contractFile);
  verifyLiveEvidence(records, contract, option("--expected-repository"), process.argv.includes("--require-negative-control"), option("--control-branch"));
  const rendered = option("--rendered");
  if (rendered && fs.readFileSync(rendered, "utf8") !== renderCriticalPathEvidence(records)) fail("rendered report does not byte-match NDJSON render");
}
