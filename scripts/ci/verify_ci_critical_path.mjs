#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
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
  return record.repository === context.expectedRepository && record.sha && record.run_attempt === 1 && record.event_class === "pull_request" && record.conclusion === "success" && record.fingerprint === context.fingerprint && Number.isFinite(record.duration_seconds);
}

export function verifyComparisonEvidence(records, contract, validationContext = {}) {
  const context = { expectedRepository: validationContext.expectedRepository || "szTheory/accrue", fingerprint: validationContext.fingerprint || "phase-227-candidate" };
  const accepted = records.filter((record) => eligible(record, contract, context));
  assert.ok(accepted.length >= 3, "fewer than three eligible first-attempt observations");
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
  assert.equal(verifyWorkflowContract(candidate, contract).state, "candidate", "intended graph passes");
  assert.equal(verifyWorkflowContract(current, contract).state, "inverse_rollback", "inverse graph remains explicit");
  assert.throws(() => verifyWorkflowContract(candidate.replace("Host integration (required deterministic gate)", "renamed"), contract), /workflow changed/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("accrue-host-server-log", "changed-artifact"), contract), /workflow changed/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("playwright-e2e,", ""), contract), /workflow changed/);
  assert.deepEqual(verifyComparisonEvidence(fixtures.accepted_evidence, contract, fixtures.context), { keep: true, median_seconds: 1600, observations: 3 });
  for (const negative of fixtures.rejected_evidence) assert.throws(() => verifyComparisonEvidence(negative, contract, fixtures.context));
  return true;
}

function option(name) { const index = process.argv.indexOf(name); return index >= 0 ? process.argv[index + 1] : null; }

if (process.argv.includes("--fixtures")) verifyFixtures();
const workflow = option("--workflow");
const contractFile = option("--contract") || path.join(phase, "227-ci-contract.json");
if (workflow) verifyWorkflowContract(fs.readFileSync(workflow, "utf8"), readJson(contractFile));
if (process.argv.includes("--require-kept")) {
  const evidence = option("--evidence");
  if (!evidence) fail("--require-kept needs --evidence");
  const records = fs.readFileSync(evidence, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse);
  const result = verifyComparisonEvidence(records, readJson(contractFile), { expectedRepository: option("--expected-repository") });
  if (!result.keep) fail("evidence is rolled back");
}
