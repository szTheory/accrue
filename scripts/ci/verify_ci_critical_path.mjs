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
  assert.match(jobBlock(workflowSource, "annotation-sweep"), /^    if: always\(\) && github\.event_name != 'schedule'$/m, "annotation-sweep must aggregate independent failures");
  for (const artifact of contract.artifacts) {
    assert.match(workflowSource, new RegExp(`uses: actions/upload-artifact@v7[\\s\\S]{0,360}name: ${artifact.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`), `artifact changed or removed: ${artifact}`);
  }
  assert.match(workflowSource, /compatibility: 'Floor'[\s\S]*?support: 'required'/, "Floor required release cell changed");
  assert.match(workflowSource, /compatibility: 'Primary dev target'[\s\S]*?sigra: 'on'[\s\S]*?support: 'advisory'/, "Sigra advisory release cell changed");
  assert.match(workflowSource, /compatibility: 'Primary dev target'[\s\S]*?opentelemetry: 'on'[\s\S]*?support: 'required'/, "OpenTelemetry required release cell changed");
  return { state: jobBlock(workflowSource, "host-integration").includes(newHostNeeds) ? "candidate" : "inverse_rollback" };
}

function dispatchInput(workflowSource, contract) {
  const input = contract.dispatch_input;
  if (!input) fail("dispatch input contract is missing");
  const dispatch = workflowSource.match(/^  workflow_dispatch:\n([\s\S]*?)(?=^  [A-Za-z_]+:|^\S|\z)/m)?.[0] || "";
  if (!dispatch) fail("workflow dispatch input is missing");
  const expected = new RegExp(`^      ${input.name}:\\n        description: .+\\n        type: ${input.type}\\n        required: ${input.required}\\n        default: ${input.default}$`, "m");
  if (!expected.test(dispatch)) fail("workflow dispatch input is missing or has the wrong Boolean contract");
  return input;
}

export function verifyMeasurementPreflight(workflowSource, contract) {
  const graph = verifyWorkflowContract(workflowSource, contract);
  if (graph.state !== "candidate") fail("candidate host edge is not active");
  const input = dispatchInput(workflowSource, contract);
  const liveStripe = jobBlock(workflowSource, "live-stripe");
  const expectedCondition = "if: ${{ needs.provider-proof-trigger.outputs.should_run == 'true' && (github.event_name == 'schedule' || github.event_name == 'push' || (github.event_name == 'workflow_dispatch' && inputs.run_live_stripe)) }}";
  if (!liveStripe.includes(expectedCondition)) fail("live-stripe must run on every schedule and only manual true dispatches");
  if (contract.measurement_topology?.event_class !== "workflow_dispatch" || contract.measurement_topology?.run_attempt !== 1 || input.measurement_value !== false) fail("measurement topology is not the authorized attempt-1 manual false dispatch");
  if (contract.run_budget?.final_candidate_attempts !== 3 || contract.run_budget?.allow_reruns || contract.run_budget?.allow_replacements) fail("candidate run budget is not exactly three independent first attempts");
  if (!Array.isArray(contract.proof_vector?.required_job_identities) || contract.proof_vector.required_job_identities.length < 12 || contract.measurement_topology.provider_state !== "non_run") fail("complete proof-vector contract is missing");
  verifySuccessArtifactContract(contract);
  return { state: graph.state, input: input.name, measurement_value: input.measurement_value, provider_state: contract.measurement_topology.provider_state };
}

export function verifySuccessArtifactContract(contract) {
  assert.deepEqual(contract.proof_vector?.expected_artifacts, ["accrue-host-phase15-screenshots"], "proof vector must require only the success-path host screenshots artifact");
  assert.ok(contract.artifacts?.includes("accrue-host-ci-setup-facts"), "failure-path setup facts must remain in the diagnostic artifact inventory");
  assert.ok(!contract.proof_vector.expected_artifacts.includes("accrue-host-ci-setup-facts"), "failure-path setup facts cannot be required by a successful proof vector");
  return true;
}

const forbiddenEvidenceKey = /(?:secret|token|password|authorization|cookie|payload|private[_-]?key)/i;
const candidateKeys = new Set(["repository", "sha", "run_id", "run_url", "run_attempt", "event_class", "inputs", "conclusion", "fingerprint", "workflow_revision", "provider_state", "duration_seconds", "required_jobs", "artifacts", "advisory"]);

function assertSafeEvidence(value, key = "root") {
  if (forbiddenEvidenceKey.test(key)) fail(`privacy-forbidden evidence key: ${key}`);
  if (typeof value === "string" && /(?:gh[ps]_[A-Za-z0-9]|sk_(?:live|test)_|bearer\s+)/i.test(value)) fail(`privacy-forbidden evidence value at ${key}`);
  if (Array.isArray(value)) return value.forEach((item, index) => assertSafeEvidence(item, `${key}[${index}]`));
  if (value && typeof value === "object") for (const [child, item] of Object.entries(value)) assertSafeEvidence(item, child);
}

function assertJobVector(record, contract) {
  const expected = contract.proof_vector.required_job_roles;
  const jobs = record.required_jobs;
  assert.ok(jobs && typeof jobs === "object" && !Array.isArray(jobs), "required jobs are missing");
  assert.deepEqual(Object.keys(jobs).sort(), [...expected].sort(), "required job keys must exactly match the contract");
  const seenUrls = new Set();
  for (const role of expected) {
    const job = jobs[role];
    assert.equal(job?.conclusion, "success", `required job did not succeed: ${role}`);
    assert.equal(job?.url, immutableJobUrl(record.repository, record.run_id, job?.job_id), `required job URL is not role-bound: ${role}`);
    assert.ok(Number.isSafeInteger(job.job_id) && job.job_id > 0, `required job id is invalid: ${role}`);
    assert.ok(!seenUrls.has(job.url), `required job URL is reused: ${role}`);
    seenUrls.add(job.url);
  }
}

function eligible(record, contract, context) {
  assertSafeEvidence(record);
  assert.deepEqual(Object.keys(record).sort(), [...candidateKeys].sort(), "candidate record has unknown or missing schema fields");
  assert.equal(record.repository, context.expectedRepository, "candidate repository differs");
  assert.match(record.sha, /^[0-9a-f]{40}$/i, "candidate SHA is invalid");
  assert.ok(Number.isSafeInteger(record.run_id) && record.run_id > 0, "candidate run id is invalid");
  assert.equal(record.run_url, immutableRunUrl(record.repository, record.run_id), "candidate run URL is not immutable");
  assert.equal(record.run_attempt, contract.measurement_topology.run_attempt, "candidate is not attempt 1");
  assert.equal(record.event_class, contract.measurement_topology.event_class, "candidate is not workflow_dispatch");
  assert.deepEqual(record.inputs, { run_live_stripe: false }, "candidate dispatch topology differs");
  assert.equal(record.conclusion, "success", "candidate raw conclusion differs");
  assert.equal(record.fingerprint, context.fingerprint || contract.measurement_topology.candidate_fingerprint, "candidate cohort fingerprint differs");
  assert.match(record.workflow_revision, new RegExp(`^${contract.measurement_topology.workflow_revision_prefix}[0-9a-f]{64}$`), "candidate workflow revision is invalid");
  assert.equal(record.provider_state, contract.measurement_topology.provider_state, "candidate provider state differs");
  assert.ok(Number.isFinite(record.duration_seconds), "candidate duration is invalid");
  assertJobVector(record, contract);
  for (const artifact of contract.proof_vector.expected_artifacts) assert.equal(record.artifacts?.[artifact], true, `candidate lacks required artifact: ${artifact}`);
  return true;
}

export function verifyComparisonEvidence(records, contract, validationContext = {}) {
  const context = { expectedRepository: validationContext.expectedRepository || "szTheory/accrue", fingerprint: validationContext.fingerprint || contract.measurement_topology.candidate_fingerprint };
  const accepted = records.filter((record) => record.repository !== undefined);
  assert.equal(accepted.length, contract.run_budget.final_candidate_attempts, "cohort must contain exactly three observations");
  for (const record of accepted) eligible(record, contract, context);
  assert.equal(new Set(accepted.map((record) => record.run_id)).size, accepted.length, "cohort run IDs must be unique");
  assert.equal(new Set(accepted.map((record) => record.sha)).size, 1, "cohort must use one exact candidate SHA");
  assert.equal(new Set(accepted.map((record) => record.workflow_revision)).size, 1, "cohort must use one exact workflow revision");
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

function latestRecord(records, kind) {
  return records.filter((record) => record.kind === kind).at(-1);
}

export function verifyContractCorrection(records, contract) {
  verifySuccessArtifactContract(contract);
  const correction = latestRecord(records, "contract_correction");
  if (!correction) fail("append-only contract_correction record is missing");
  assert.equal(correction.correction_id, "phase-227-success-artifact-v1", "contract correction id changed");
  assert.deepEqual(correction.prior_expected_artifacts, ["accrue-host-ci-setup-facts", "accrue-host-phase15-screenshots"], "prior impossible artifact vector is not preserved");
  assert.deepEqual(correction.corrected_expected_artifacts, contract.proof_vector.expected_artifacts, "correction does not match the active proof vector");
  assert.equal(correction.diagnostic_artifact_retained_in_inventory, "accrue-host-ci-setup-facts", "diagnostic artifact inventory correction is incomplete");
  assert.equal(correction.historical_records_rewritten, false, "historical evidence must remain append-only");
  assert.equal(correction.restoration_dispatch_consumed, false, "contract correction must precede the restoration dispatch");
  return correction;
}

function candidateRequiredPathPassed(record) {
  const jobs = Object.values(record.required_jobs || {});
  return jobs.length >= 10 && jobs.every((job) => job?.conclusion === "success");
}

export function correctedCandidateAdmissions(records, contract) {
  const correction = verifyContractCorrection(records, contract);
  const candidates = new Map(records.filter((record) => record.kind === "candidate_run").map((record) => [record.run_id, record]));
  const reclassifications = records.filter((record) => record.kind === "candidate_reclassification" && record.correction_id === correction.correction_id);
  const admitted = [];
  for (const reclassification of reclassifications) {
    const candidate = candidates.get(reclassification.run_id);
    if (!candidate) fail(`reclassification has no historical candidate_run: ${reclassification.run_id}`);
    requireRecordUrl(reclassification, "run_url", immutableRunUrl(reclassification.repository, reclassification.run_id));
    if (candidate.repository !== reclassification.repository || candidate.run_url !== reclassification.run_url || candidate.run_attempt !== 1 || candidate.event_class !== "workflow_dispatch") fail(`reclassification identity differs from historical run: ${reclassification.run_id}`);
    if (candidate.conclusion !== "success" || !candidateRequiredPathPassed(candidate) || candidate.provider_state !== "non_run") fail(`reclassified candidate did not pass the corrected required path: ${reclassification.run_id}`);
    if (candidate.artifacts?.["accrue-host-phase15-screenshots"] !== true || reclassification.corrected_expected_artifacts?.["accrue-host-phase15-screenshots"] !== true) fail(`reclassified candidate lacks the success-path artifact: ${reclassification.run_id}`);
    if (reclassification.prior_classification !== "candidate_regression" || reclassification.corrected_classification !== "admitted_observation" || reclassification.corrected_proof_vector_complete !== true || reclassification.required_job_outcomes !== "passed" || reclassification.live_revalidated !== true || reclassification.historical_record_rewritten !== false) fail(`reclassification contract is incomplete: ${reclassification.run_id}`);
    admitted.push(candidate);
  }
  assert.equal(new Set(admitted.map((record) => record.run_id)).size, admitted.length, "candidate reclassification is duplicated");
  return admitted;
}

export function verifyRollbackTerminal(records, contract, expectedRepository = "szTheory/accrue") {
  verifyContractCorrection(records, contract);
  const rollback = latestRecord(records, "rollback");
  if (!rollback || rollback.state !== "rollback_verified") fail("latest rollback state is not rollback_verified");
  const run = rollback.restoration_run;
  if (!run || run.repository !== expectedRepository || run.sha !== rollback.restored_sha || rollback.inverse_commit !== rollback.restored_sha) fail("rollback restoration identity is inconsistent");
  if (run.run_attempt !== 1 || run.event_class !== "workflow_dispatch" || run.inputs?.run_live_stripe !== true || run.conclusion !== "success") fail("rollback restoration run is not the authorized successful attempt-1 live-Stripe dispatch");
  requireRecordUrl(run, "run_url", immutableRunUrl(expectedRepository, run.run_id));
  if (run.required_path?.host?.conclusion !== "success" || run.required_path?.annotation?.conclusion !== "success" || run.required_path?.playwright?.conclusion !== "success" || !Array.isArray(run.required_path.playwright.urls) || run.required_path.playwright.urls.length !== 3) fail("rollback restoration required path did not pass");
  if (!run.provider || run.provider.state !== "proved" || run.provider.conclusion !== "success") fail("rollback restoration provider proof is not proved");
  const immutablePrefix = `${immutableRunUrl(expectedRepository, run.run_id)}/job/`;
  for (const url of [run.required_path.host.url, run.required_path.annotation.url, ...run.required_path.playwright.urls, run.provider.url]) {
    if (!String(url || "").startsWith(immutablePrefix) || !/\/job\/\d+$/.test(url)) fail("rollback restoration job URL is not immutable and repository-bound");
  }
  for (const artifact of contract.proof_vector.expected_artifacts) if (run.artifacts?.[artifact] !== true) fail(`rollback restoration lacks required artifact: ${artifact}`);
  if (run.artifacts?.["live-stripe-proof"] !== true) fail("rollback restoration lacks live-stripe-proof");
  return rollback;
}

function verifyRestorationDispatchTransport(records, rollback, expectedRepository) {
  const transport = latestRecord(records, "restoration_dispatch_transport");
  const run = rollback.restoration_run;
  if (!transport || transport.repository !== expectedRepository || transport.target_sha !== rollback.restored_sha) fail("restoration dispatch transport identity is inconsistent");
  if (transport.accepted_run_id !== run.run_id || transport.accepted_run_url !== run.run_url || transport.actual_authorized_runs_consumed !== 1) fail("restoration dispatch transport does not bind the sole authorized run");
  if (transport.direct_sha_dispatch?.result !== "rejected_no_run" || transport.direct_sha_dispatch?.http_status !== 422 || transport.direct_sha_dispatch?.run_created !== false || transport.direct_sha_dispatch?.budget_consumed !== false) fail("rejected direct-SHA dispatch is not recorded as a non-run");
  if (!transport.temporary_ref?.name || transport.temporary_ref?.pointed_to_target_sha !== true || transport.temporary_ref?.removed_after_run_binding !== true) fail("temporary restoration ref lifecycle is incomplete");
  return transport;
}

export function verifyUnverifiedRollbackTerminal(records, contract, expectedRepository = "szTheory/accrue") {
  verifyContractCorrection(records, contract);
  const rollback = latestRecord(records, "rollback");
  if (!rollback || rollback.state !== "rollback_applied_unverified") fail("latest rollback state is not rollback_applied_unverified");
  const run = rollback.restoration_run;
  if (!run || run.repository !== expectedRepository || run.sha !== rollback.restored_sha || rollback.inverse_commit !== rollback.restored_sha) fail("unverified rollback restoration identity is inconsistent");
  if (run.run_attempt !== 1 || run.event_class !== "workflow_dispatch" || run.inputs?.run_live_stripe !== true || run.conclusion !== "failure") fail("unverified rollback restoration run is not the authorized failed attempt-1 live-Stripe dispatch");
  requireRecordUrl(run, "run_url", immutableRunUrl(expectedRepository, run.run_id));
  if (run.required_path?.host?.conclusion !== "success" || run.required_path?.annotation?.conclusion !== "success" || run.required_path?.playwright?.conclusion !== "success" || !Array.isArray(run.required_path.playwright.urls) || run.required_path.playwright.urls.length !== 3) fail("unverified rollback required path did not pass");
  const provider = run.provider;
  if (!provider || provider.state !== "misconfigured" || provider.conclusion !== "failure" || provider.reason_code !== "manifest_invalid" || provider.selected_count !== 0 || provider.manifest_written !== false) fail("unverified rollback provider failure is incomplete");
  const immutablePrefix = `${immutableRunUrl(expectedRepository, run.run_id)}/job/`;
  for (const url of [run.required_path.host.url, run.required_path.annotation.url, ...run.required_path.playwright.urls, provider.url]) {
    if (!String(url || "").startsWith(immutablePrefix) || !/\/job\/\d+$/.test(url)) fail("unverified rollback job URL is not immutable and repository-bound");
  }
  for (const artifact of contract.proof_vector.expected_artifacts) if (run.artifacts?.[artifact] !== true) fail(`unverified rollback lacks required artifact: ${artifact}`);
  if (run.artifacts?.["live-stripe-proof"] !== true || run.artifacts?.["accrue-host-ci-setup-facts"] !== false) fail("unverified rollback artifact inventory is incomplete");
  if (rollback.run_budget !== "exhausted" || rollback.additional_dispatch_authorized !== false || rollback.next_command !== null) fail("unverified rollback must close the restoration run budget");
  verifyRestorationDispatchTransport(records, rollback, expectedRepository);
  return rollback;
}

export function verifyFinalDecision(records, contract, expectedRepository = "szTheory/accrue") {
  const admitted = correctedCandidateAdmissions(records, contract);
  if (admitted.length >= contract.run_budget.final_candidate_attempts) fail("rollback decision is inconsistent with a complete admitted cohort");
  const rollback = latestRecord(records, "rollback");
  if (!rollback || !["rollback_verified", "rollback_applied_unverified"].includes(rollback.state)) fail("terminal rollback decision is missing");
  if (rollback.state === "rollback_verified") verifyRollbackTerminal(records, contract, expectedRepository);
  else verifyUnverifiedRollbackTerminal(records, contract, expectedRepository);
  return { state: rollback.state, admitted_observations: admitted.length };
}

export function verifyFixtures(workflowFixture = path.join(phase, "fixtures/ci-workflow-restored-v2.yml")) {
  const contract = readJson(path.join(phase, "227-ci-contract.json"));
  const fixtures = readJson(path.join(phase, "fixtures/ci-critical-path-cases.json"));
  const validCandidate = (run_id, duration_seconds) => ({
    repository: "szTheory/accrue", sha: "a".repeat(40), run_id,
    run_url: immutableRunUrl("szTheory/accrue", run_id), run_attempt: 1,
    event_class: "workflow_dispatch", inputs: { run_live_stripe: false }, conclusion: "success",
    fingerprint: contract.measurement_topology.candidate_fingerprint,
    workflow_revision: `sha256:${"b".repeat(64)}`, provider_state: "non_run", duration_seconds,
    required_jobs: Object.fromEntries(contract.proof_vector.required_job_roles.map((role, index) => [role, { conclusion: "success", job_id: run_id * 100 + index + 1, url: immutableJobUrl("szTheory/accrue", run_id, run_id * 100 + index + 1) }])),
    artifacts: { "accrue-host-phase15-screenshots": true }, advisory: { sigra: "advisory", parked_ratchet: "advisory" },
  });
  const exactCohort = [validCandidate(101, 1580), validCandidate(102, 1600), validCandidate(103, 1650), { aggregate_failure: true, host_browser_completed: true, artifacts_retained: true }];
  assert.deepEqual(verifyComparisonEvidence(exactCohort, contract), { keep: true, median_seconds: 1600, observations: 3 });
  assert.throws(() => verifyComparisonEvidence(fixtures.forged_keep_evidence, contract, fixtures.context), /workflow_dispatch|unique|required job|schema fields/, "forged duplicate push cohort must be rejected through the public verifier");
  const restored = fs.readFileSync(workflowFixture, "utf8");
  const host = jobBlock(restored, "host-integration");
  const candidate = restored.replace(host, host.replace(oldHostNeeds, newHostNeeds));
  const rollback = restored.replace(host, host.replace(newHostNeeds, oldHostNeeds));
  verifySuccessArtifactContract(contract);
  assert.equal(verifyWorkflowContract(candidate, contract).state, "candidate", "intended graph passes");
  assert.equal(verifyWorkflowContract(rollback, contract).state, "inverse_rollback", "inverse graph remains explicit");
  assert.throws(() => verifyMeasurementPreflight(rollback, contract), /candidate host edge is not active/, "restored graph cannot admit a candidate");
  assert.deepEqual(verifyMeasurementPreflight(candidate, contract), { state: "candidate", input: "run_live_stripe", measurement_value: false, provider_state: "non_run" });
  assert.throws(() => verifyMeasurementPreflight(candidate.replace("default: true", "default: false"), contract), /workflow changed|wrong Boolean contract/);
  assert.throws(() => verifyMeasurementPreflight(candidate.replace("required: true", "required: false"), contract), /workflow changed|wrong Boolean contract/);
  assert.throws(() => verifyMeasurementPreflight(candidate.replace("inputs.run_live_stripe", "true"), contract), /workflow changed|manual true dispatches/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("Host integration (required deterministic gate)", "renamed"), contract), /workflow changed/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("accrue-host-server-log", "changed-artifact"), contract), /workflow changed/);
  assert.throws(() => verifyWorkflowContract(candidate.replace("playwright-e2e,", ""), contract), /workflow changed/);
  return true;
}

function option(name) { const index = process.argv.indexOf(name); return index >= 0 ? process.argv[index + 1] : null; }

const forbiddenEvidenceFields = /(?:actor|branch|token|secret|log|payload|artifact_content|user_data)/i;
const allowedCredentialStatusFields = new Set(["required_repository_secrets"]);
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
    for (const key of Object.keys(record)) if (forbiddenEvidenceFields.test(key) && !allowedCredentialStatusFields.has(key)) fail(`evidence line ${index + 1} contains forbidden field ${key}`);
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

function jobIdFromUrl(url) {
  const match = String(url || "").match(/\/job\/(\d+)$/);
  if (!match) fail(`job URL is not immutable: ${url}`);
  return Number(match[1]);
}

function verifyRecordedJob(jobs, repository, runId, recorded, label) {
  const jobId = jobIdFromUrl(recorded?.url);
  const job = jobs.find((item) => item.id === jobId);
  if (!job || job.conclusion !== recorded.conclusion || recorded.url !== immutableJobUrl(repository, runId, jobId)) fail(`live ${label} job differs for ${runId}`);
  return job;
}

function verifyLiveReclassifications(records, contract, repository) {
  const admitted = correctedCandidateAdmissions(records, contract);
  for (const record of admitted) {
    const run = api(`repos/${repository}/actions/runs/${record.run_id}`);
    if (run.head_sha !== record.sha || run.run_attempt !== record.run_attempt || run.event !== record.event_class || run.conclusion !== record.conclusion) fail(`live candidate facts differ for ${record.run_id}`);
    requireRecordUrl(record, "run_url", immutableRunUrl(repository, record.run_id));
    if (workflowRevision(repository, record.sha) !== record.workflow_revision) fail(`candidate workflow revision differs for ${record.run_id}`);
    const jobs = api(`repos/${repository}/actions/runs/${record.run_id}/attempts/${record.run_attempt}/jobs?filter=all&per_page=100`).jobs;
    if (!Array.isArray(jobs)) fail(`live candidate jobs are unavailable for ${record.run_id}`);
    for (const [label, recorded] of Object.entries(record.required_jobs)) {
      if (label === "playwright") {
        if (!Array.isArray(recorded.urls) || recorded.urls.length !== 3) fail(`recorded Playwright shard set is incomplete for ${record.run_id}`);
        for (const url of recorded.urls) verifyRecordedJob(jobs, repository, record.run_id, { url, conclusion: recorded.conclusion }, "Playwright");
      } else {
        verifyRecordedJob(jobs, repository, record.run_id, recorded, label);
      }
    }
    const names = new Set(api(`repos/${repository}/actions/runs/${record.run_id}/artifacts?per_page=100`).artifacts.map((artifact) => artifact.name));
    for (const artifact of contract.proof_vector.expected_artifacts) if (!names.has(artifact)) fail(`live candidate lacks corrected artifact ${artifact}: ${record.run_id}`);
  }
  return true;
}

function verifyLiveRollback(records, contract, repository, requireVerified = false) {
  const latest = latestRecord(records, "rollback");
  const rollback = latest?.state === "rollback_verified"
    ? verifyRollbackTerminal(records, contract, repository)
    : verifyUnverifiedRollbackTerminal(records, contract, repository);
  if (requireVerified && rollback.state !== "rollback_verified") fail("latest rollback state is not rollback_verified");
  const record = rollback.restoration_run;
  const run = api(`repos/${repository}/actions/runs/${record.run_id}`);
  if (run.head_sha !== record.sha || run.run_attempt !== record.run_attempt || run.event !== record.event_class || run.conclusion !== record.conclusion) fail(`live rollback facts differ for ${record.run_id}`);
  requireRecordUrl(record, "run_url", immutableRunUrl(repository, record.run_id));
  if (workflowRevision(repository, record.sha) !== record.workflow_revision) fail(`rollback workflow revision differs for ${record.run_id}`);
  const jobs = api(`repos/${repository}/actions/runs/${record.run_id}/attempts/${record.run_attempt}/jobs?filter=all&per_page=100`).jobs;
  if (!Array.isArray(jobs)) fail(`live rollback jobs are unavailable for ${record.run_id}`);
  verifyRecordedJob(jobs, repository, record.run_id, record.required_path.host, "host");
  verifyRecordedJob(jobs, repository, record.run_id, record.required_path.annotation, "annotation");
  for (const url of record.required_path.playwright.urls) verifyRecordedJob(jobs, repository, record.run_id, { url, conclusion: "success" }, "Playwright");
  verifyRecordedJob(jobs, repository, record.run_id, record.provider, "provider");
  const names = new Set(api(`repos/${repository}/actions/runs/${record.run_id}/artifacts?per_page=100`).artifacts.map((artifact) => artifact.name));
  for (const artifact of [...contract.proof_vector.expected_artifacts, "live-stripe-proof"]) if (!names.has(artifact)) fail(`live rollback lacks required artifact ${artifact}: ${record.run_id}`);
  if (rollback.state === "rollback_applied_unverified") {
    const transport = verifyRestorationDispatchTransport(records, rollback, repository);
    if (apiErrorStatus(`repos/${repository}/git/ref/heads/${transport.temporary_ref.name}`) === 0) fail("temporary restoration ref still exists");
  }
  return true;
}

export function renderCriticalPathEvidence(records) {
  const contract = readJson(path.join(phase, "227-ci-contract.json"));
  validateTerminalLedger(records, contract);
  const candidateRuns = records.filter((record) => record.kind === "candidate_run");
  const control = records.find((record) => record.kind === "negative_control" && record.run_id);
  const correction = latestRecord(records, "contract_correction");
  const reclassifications = records.filter((record) => record.kind === "candidate_reclassification" && record.correction_id === correction.correction_id);
  const historicalRollback = records.filter((record) => record.kind === "rollback")[0];
  const rollback = latestRecord(records, "rollback");
  const recovery = latestRecord(records, "recovery_preflight");
  const transport = latestRecord(records, "restoration_dispatch_transport");
  const date = (value) => new Intl.DateTimeFormat("en-CA", { timeZone: "America/New_York" }).format(new Date(value));
  const words = new Map([[2, "two"], [3, "three"]]);
  const written = (number) => words.get(number) || String(number);
  const candidateRows = candidateRuns.map((record) => {
    const evidenceGap = record.classification === "candidate_regression"
      ? `Required \`${correction.prior_expected_artifacts[0]}\` artifact absent.`
      : record.exclusion_reason.replace("and the aggregate finalizer failed", "and \`annotation-sweep\` failed").replace(", so this attempt is not eligible.", ".");
    return `| [${record.run_id}](${record.run_url}) | ${record.conclusion} | \`${record.classification}\` | ${evidenceGap} |`;
  }).join("\n");
  const reclassificationRows = reclassifications.map((record) => `| [${record.run_id}](${record.run_url}) | \`${record.prior_classification}\` | \`${record.corrected_classification}\` | ${record.required_job_outcomes} | ${Object.entries(record.corrected_expected_artifacts).filter(([, present]) => present).map(([artifact]) => `\`${artifact}\` present`).join(", ")} |`).join("\n");
  const secretNames = Object.keys(recovery.required_repository_secrets).map((name) => `- \`${name}\``).join("\n");
  const firstCandidate = candidateRuns[0];
  const historical = historicalRollback.restoration_run;
  const latest = rollback.restoration_run;
  return `# Phase 227 critical-path rollback\n\n## Current fact\n\nThe corrected final candidate cohort admits only ${written(reclassifications.length)} of the ${written(contract.run_budget.final_candidate_attempts)} required first-attempt proof vectors. The exact D-11 inverse is present at \`${rollback.restored_sha}\`. The single post-correction restoration dispatch completed, but a missing Stripe webhook signing secret stopped the live suite during application boot.\n\n## Rollback\n\n- state: \`${rollback.state}\`\n- owner: ${rollback.owner}\n- restoration run budget: \`${rollback.run_budget}\`\n- additional dispatch authorized: \`${rollback.additional_dispatch_authorized}\`\n- next command: none\n\nNo candidate rerun or replacement was launched. Exactly one restoration run was created after the contract correction, and no further dispatch is authorized.\n\n## Recovery preflight (${date(recovery.checked_at)})\n\nThe recovery gate was diagnosed from the immutable provider-job log and repository configuration. The job received blank values for all three required inputs, and the repository has none of the required secret names configured:\n\n${secretNames}\n\nThe task-scoped environment also contained none of these values. Their values were not read or printed. This was the accurate preflight state on ${date(recovery.checked_at)}; the ${date(rollback.recorded_at)} outcome below supersedes its recovery instruction.\n\n## Final candidate proof vectors\n\n| Run | Raw conclusion | Classification | Evidence gap / failure |\n| --- | --- | --- | --- |\n${candidateRows}\n\nAll three are immutable \`${firstCandidate.event_class}\`, attempt-${firstCandidate.run_attempt} records at candidate SHA \`${firstCandidate.sha}\` with \`run_live_stripe: false\` and provider state \`${firstCandidate.provider_state}\`. Their complete repository-bound job URLs, artifact presence, advisory outcomes, workflow revision, and exclusions are retained in the NDJSON ledger.\n\n## Historical restoration proof\n\n[${historical.run_id}](${historical.run_url}) is the pre-correction attempt-${historical.run_attempt} \`${historical.event_class}\` at restored SHA \`${historical.sha}\`, with \`run_live_stripe: true\`. Host integration, all three Playwright shards, and \`annotation-sweep\` succeeded; the \`live-stripe\` provider preflight failed and emitted its artifact, so the raw workflow conclusion is \`${historical.conclusion}\`. This immutable historical record is retained unchanged but did not meet the fresh-success requirement for \`rollback_verified\`.\n\n## Preserved controls\n\n- The admissible negative control [${control.run_id}](${control.run_url}) remains visible.\n- All nine older exclusions and the earlier inadmissible control remain byte-present in the NDJSON ledger.\n- The inverse workflow contract, critical-path fixtures, frozen Phase 226 baseline, provider fixtures, setup diagnostics, and Phase 225 preservation controls passed locally.\n\nPATH-02 is unmet: this report records a safe applied rollback with an explicit external proof gap, not a kept comparison.\n\n## Post-recovery contract correction (${date(correction.recorded_at)})\n\nThe original proof vector mistakenly required \`${correction.prior_expected_artifacts[0]}\` while also requiring \`host-integration\` to succeed. That artifact is a failure-path diagnostic: the workflow and host UAT script emit it only when setup or \`mix verify.full\` fails, and the upload step ignores a missing file on successful runs. No run at any SHA could satisfy both predicates.\n\nThe contract now requires the success-path \`${correction.corrected_expected_artifacts[0]}\` artifact and retains \`${correction.diagnostic_artifact_retained_in_inventory}\` in the broader artifact inventory as a failure diagnostic. This is a transparent forward correction recorded after the failed recovery; no historical fingerprint, run record, or earlier classification was edited or backdated.\n\nRead-only GitHub reconciliation revalidated the two successful candidate runs against every remaining predicate:\n\n| Run | Prior classification | Corrected classification | Required path | Success artifact |\n| --- | --- | --- | --- | --- |\n${reclassificationRows}\n\nThese append-only reclassifications supersede the artifact-only exclusions in the historical table above. Run \`${candidateRuns.find((record) => record.conclusion !== "success").run_id}\` remains excluded for its deterministic required-lane failure. The corrected cohort therefore has only ${written(reclassifications.length)} admitted observations, fewer than the ${written(contract.run_budget.final_candidate_attempts)} required by the bounded measurement contract; rollback remains the honest decision. At the time of this correction the single authorized restoration dispatch was still unspent, and the correction itself made no Stripe configuration or workflow mutation.\n\n## Authorized restoration outcome (${date(rollback.recorded_at)})\n\nThe three repository Stripe inputs were configured without exposing their values. A literal SHA dispatch was rejected by GitHub with HTTP ${transport.direct_sha_dispatch.http_status} and created no run, so it did not consume the budget. A temporary ref pointing exactly to restored SHA \`${transport.target_sha}\` was then used for the one authorized dispatch and removed immediately after run identity was bound.\n\n[${latest.run_id}](${latest.run_url}) is that sole attempt-${latest.run_attempt} \`${latest.event_class}\`, with \`run_live_stripe: true\`. Host integration, all three Playwright shards, and \`annotation-sweep\` succeeded. \`${contract.proof_vector.expected_artifacts[0]}\` and \`live-stripe-proof\` are present; the failure-only setup-facts artifact is correctly absent.\n\nThe three key/price preflight inputs passed. The provider job then failed before selecting any live test because application boot raised \`ACCRUE-DX-WEBHOOK-SECRET-MISSING\`: the Stripe processor webhook signing secret was absent. The emitted proof classifies this as \`${latest.provider.state}\` / \`${latest.provider.reason_code}\`, with zero selected tests and no manifest written. Therefore the run cannot establish \`rollback_verified\`.\n\nThe restoration budget is exhausted. No rerun or replacement is authorized. Phase 227 remains terminally blocked at \`${rollback.state}\`; Task 3 stays skipped and PATH-02 remains unmet.\n`;
}

function validateTerminalLedger(records, contract) {
  const expectedPrefix = ["negative_control", "exclusion", "negative_control", ...Array(9).fill("exclusion"), "decision_pending"];
  assert.deepEqual(records.slice(0, expectedPrefix.length).map((record) => record.kind), expectedPrefix, "historical ledger prefix changed");
  for (const record of records) assertSafeTerminalEvidence(record);
  assert.equal(records.filter((record) => record.kind === "candidate_run").length, contract.run_budget.final_candidate_attempts, "terminal ledger must retain exactly three candidate attempts");
  assert.equal(records.filter((record) => record.kind === "candidate_reclassification").length, 2, "terminal ledger must retain both append-only reclassifications");
  verifyFinalDecision(records, contract);
}

function assertSafeTerminalEvidence(value, key = "root", parent = "") {
  const credentialStatusObject = key === "required_repository_secrets" || key === "task_scoped_environment";
  if (forbiddenEvidenceKey.test(key) && !(credentialStatusObject && parent === "recovery_preflight") && parent !== "required_repository_secrets" && parent !== "task_scoped_environment") fail(`privacy-forbidden evidence key: ${key}`);
  if (typeof value === "string" && /(?:gh[ps]_[A-Za-z0-9]|sk_(?:live|test)_|bearer\s+)/i.test(value)) fail(`privacy-forbidden evidence value at ${key}`);
  if (Array.isArray(value)) return value.forEach((item, index) => assertSafeTerminalEvidence(item, `${key}[${index}]`, parent));
  if (value && typeof value === "object") {
    if (credentialStatusObject) for (const status of Object.values(value)) assert.equal(status, "absent", "credential status must not contain a value");
    for (const [child, item] of Object.entries(value)) assertSafeTerminalEvidence(item, child, credentialStatusObject ? key : (value.kind || parent));
  }
}

function parseCli(argv) {
  const actions = new Set(["--fixtures", "--verify-workflow", "--verify-evidence", "--render-evidence", "--verify-live-actions"]);
  const values = new Set(["--workflow", "--workflow-fixture", "--contract", "--evidence", "--rendered", "--expected-repository", "--control-branch"]);
  const modifiers = new Set(["--require-final-decision", "--require-rollback-verified", "--require-negative-control"]);
  const seen = new Map();
  const flags = new Set();
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) fail(`unexpected positional argument: ${token}`);
    if (actions.has(token) || modifiers.has(token)) { if (flags.has(token)) fail(`duplicate option: ${token}`); flags.add(token); continue; }
    if (!values.has(token)) fail(`unknown option: ${token}`);
    const value = argv[++index];
    if (!value || value.startsWith("--")) fail(`missing value for ${token}`);
    if (seen.has(token)) fail(`duplicate option: ${token}`);
    seen.set(token, value);
  }
  const selected = [...flags].filter((flag) => actions.has(flag));
  if (selected.length !== 1) fail("exactly one primary action is required");
  const action = selected[0];
  const allowed = {
    "--fixtures": new Set(["--workflow-fixture", "--contract"]),
    "--verify-workflow": new Set(["--workflow", "--contract"]),
    "--verify-evidence": new Set(["--evidence", "--contract", "--expected-repository", "--rendered", "--require-final-decision", "--require-rollback-verified"]),
    "--render-evidence": new Set(["--evidence", "--contract", "--expected-repository", "--rendered"]),
    "--verify-live-actions": new Set(["--evidence", "--contract", "--expected-repository", "--rendered", "--control-branch", "--require-final-decision", "--require-rollback-verified", "--require-negative-control"]),
  }[action];
  for (const optionName of [...seen.keys(), ...flags]) if (optionName !== action && !allowed.has(optionName)) fail(`${optionName} is not allowed with ${action}`);
  return { action, values: seen, flags };
}

function runCli(argv) {
  const cli = parseCli(argv);
  const contractFile = cli.values.get("--contract") || path.join(phase, "227-ci-contract.json");
  const contract = readJson(contractFile);
  if (cli.action === "--fixtures") return verifyFixtures(cli.values.get("--workflow-fixture"));
  if (cli.action === "--verify-workflow") {
    const workflow = cli.values.get("--workflow"); if (!workflow) fail("--verify-workflow requires --workflow");
    return verifyWorkflowContract(fs.readFileSync(workflow, "utf8"), contract);
  }
  const evidence = cli.values.get("--evidence"); if (!evidence) fail(`${cli.action} requires --evidence`);
  const records = evidenceRecords(evidence);
  const repository = cli.values.get("--expected-repository") || "szTheory/accrue";
  if (cli.action === "--verify-evidence") {
    const result = verifyFinalDecision(records, contract, repository);
    const rendered = cli.values.get("--rendered");
    if (rendered && fs.readFileSync(rendered, "utf8") !== renderCriticalPathEvidence(records)) fail("rendered report does not byte-match NDJSON render");
    return result;
  }
  if (cli.action === "--render-evidence") {
    const rendered = cli.values.get("--rendered"); if (!rendered) fail("--render-evidence requires --rendered");
    const output = renderCriticalPathEvidence(records); if (fs.readFileSync(rendered, "utf8") !== output) fail("rendered report does not byte-match NDJSON render");
    return true;
  }
  if (records.some((record) => record.kind === "contract_correction")) {
    verifyLiveReclassifications(records, contract, repository);
    if (cli.flags.has("--require-final-decision") || cli.flags.has("--require-rollback-verified")) verifyLiveRollback(records, contract, repository, cli.flags.has("--require-rollback-verified"));
  } else verifyLiveEvidence(records, contract, repository, cli.flags.has("--require-negative-control"), cli.values.get("--control-branch"));
  return true;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) runCli(process.argv.slice(2));
