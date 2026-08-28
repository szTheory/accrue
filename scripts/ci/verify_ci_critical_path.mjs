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
  const expectedCondition = "if: ${{ github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && inputs.run_live_stripe) }}";
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

export function verifyFixtures() {
  const contract = readJson(path.join(phase, "227-ci-contract.json"));
  const fixtures = readJson(path.join(phase, "fixtures/ci-critical-path-cases.json"));
  const current = fs.readFileSync(path.join(root, ".github/workflows/ci.yml"), "utf8");
  const host = jobBlock(current, "host-integration");
  const candidate = current.replace(host, host.replace(oldHostNeeds, newHostNeeds));
  const rollback = current.replace(host, host.replace(newHostNeeds, oldHostNeeds));
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
  assert.deepEqual(verifyComparisonEvidence(fixtures.accepted_evidence, contract, fixtures.context), { keep: true, median_seconds: 1600, observations: 3 });
  for (const negative of fixtures.rejected_evidence) assert.throws(() => verifyComparisonEvidence(negative, contract, fixtures.context));
  const correction = { schema_version: 1, kind: "contract_correction", correction_id: "phase-227-success-artifact-v1", prior_expected_artifacts: ["accrue-host-ci-setup-facts", "accrue-host-phase15-screenshots"], corrected_expected_artifacts: ["accrue-host-phase15-screenshots"], diagnostic_artifact_retained_in_inventory: "accrue-host-ci-setup-facts", historical_records_rewritten: false, restoration_dispatch_consumed: false };
  const requiredJobs = Object.fromEntries(Array.from({ length: 10 }, (_, index) => [`job_${index}`, { conclusion: "success" }]));
  const fixtureCandidate = (runId) => ({ kind: "candidate_run", repository: "szTheory/accrue", run_id: runId, run_url: immutableRunUrl("szTheory/accrue", runId), run_attempt: 1, event_class: "workflow_dispatch", conclusion: "success", provider_state: "non_run", required_jobs: requiredJobs, artifacts: { "accrue-host-phase15-screenshots": true } });
  const reclassification = (runId) => ({ kind: "candidate_reclassification", correction_id: correction.correction_id, repository: "szTheory/accrue", run_id: runId, run_url: immutableRunUrl("szTheory/accrue", runId), prior_classification: "candidate_regression", corrected_classification: "admitted_observation", corrected_proof_vector_complete: true, corrected_expected_artifacts: { "accrue-host-phase15-screenshots": true }, required_job_outcomes: "passed", live_revalidated: true, historical_record_rewritten: false });
  const fixtureJobUrl = (jobId) => immutableJobUrl("szTheory/accrue", 3, jobId);
  const verifiedRollback = { kind: "rollback", state: "rollback_verified", restored_sha: "a".repeat(40), inverse_commit: "a".repeat(40), restoration_run: { repository: "szTheory/accrue", run_id: 3, run_url: immutableRunUrl("szTheory/accrue", 3), sha: "a".repeat(40), run_attempt: 1, event_class: "workflow_dispatch", inputs: { run_live_stripe: true }, conclusion: "success", required_path: { host: { conclusion: "success", url: fixtureJobUrl(1) }, playwright: { conclusion: "success", urls: [fixtureJobUrl(2), fixtureJobUrl(3), fixtureJobUrl(4)] }, annotation: { conclusion: "success", url: fixtureJobUrl(5) } }, provider: { state: "proved", conclusion: "success", url: fixtureJobUrl(6) }, artifacts: { "accrue-host-phase15-screenshots": true, "live-stripe-proof": true } } };
  const unverifiedRollback = { ...verifiedRollback, state: "rollback_applied_unverified", run_budget: "exhausted", additional_dispatch_authorized: false, next_command: null, restoration_run: { ...verifiedRollback.restoration_run, conclusion: "failure", provider: { state: "misconfigured", conclusion: "failure", url: fixtureJobUrl(6), reason_code: "manifest_invalid", selected_count: 0, manifest_written: false }, artifacts: { ...verifiedRollback.restoration_run.artifacts, "accrue-host-ci-setup-facts": false } } };
  const terminal = [correction, fixtureCandidate(1), fixtureCandidate(2), reclassification(1), reclassification(2), verifiedRollback];
  assert.deepEqual(verifyFinalDecision(terminal, contract), { state: "rollback_verified", admitted_observations: 2 });
  assert.equal(verifyRollbackTerminal(terminal, contract), verifiedRollback);
  const transport = { kind: "restoration_dispatch_transport", repository: "szTheory/accrue", target_sha: "a".repeat(40), direct_sha_dispatch: { result: "rejected_no_run", http_status: 422, run_created: false, budget_consumed: false }, temporary_ref: { name: "fixture-ref", pointed_to_target_sha: true, removed_after_run_binding: true }, accepted_run_id: 3, accepted_run_url: immutableRunUrl("szTheory/accrue", 3), actual_authorized_runs_consumed: 1 };
  const unverifiedTerminal = terminal.slice(0, -1).concat(transport, unverifiedRollback);
  assert.deepEqual(verifyFinalDecision(unverifiedTerminal, contract), { state: "rollback_applied_unverified", admitted_observations: 2 });
  assert.equal(verifyUnverifiedRollbackTerminal(unverifiedTerminal, contract), unverifiedRollback);
  assert.throws(() => verifySuccessArtifactContract({ ...contract, proof_vector: { ...contract.proof_vector, expected_artifacts: ["accrue-host-ci-setup-facts", "accrue-host-phase15-screenshots"] } }), /success-path host screenshots artifact/);
  assert.throws(() => verifyRollbackTerminal(terminal.slice(0, -1).concat({ ...verifiedRollback, state: "rollback_applied_unverified" }), contract), /not rollback_verified/);
  assert.throws(() => verifyRollbackTerminal(terminal.slice(0, -1).concat({ ...verifiedRollback, restoration_run: { ...verifiedRollback.restoration_run, artifacts: { "live-stripe-proof": true } } }), contract), /required artifact/);
  assert.throws(() => verifyRollbackTerminal(terminal.slice(0, -1).concat({ ...verifiedRollback, restoration_run: { ...verifiedRollback.restoration_run, provider: { state: "failed", conclusion: "failure" } } }), contract), /provider proof/);
  assert.throws(() => verifyRollbackTerminal(terminal.slice(0, -1).concat({ ...verifiedRollback, restoration_run: { ...verifiedRollback.restoration_run, run_attempt: 2 } }), contract), /authorized successful attempt-1/);
  assert.throws(() => verifyRollbackTerminal(terminal.slice(0, -1).concat({ ...verifiedRollback, restoration_run: { ...verifiedRollback.restoration_run, sha: "b".repeat(40) } }), contract), /identity is inconsistent/);
  assert.throws(() => verifyRollbackTerminal(terminal.slice(0, -1).concat({ ...verifiedRollback, restoration_run: { ...verifiedRollback.restoration_run, required_path: { ...verifiedRollback.restoration_run.required_path, host: { ...verifiedRollback.restoration_run.required_path.host, conclusion: "failure" } } } }), contract), /required path did not pass/);
  assert.throws(() => verifyUnverifiedRollbackTerminal(unverifiedTerminal.slice(0, -1).concat({ ...unverifiedRollback, run_budget: "available" }), contract), /close the restoration run budget/);
  assert.throws(() => verifyUnverifiedRollbackTerminal(unverifiedTerminal.slice(0, -1).concat({ ...unverifiedRollback, restoration_run: { ...unverifiedRollback.restoration_run, provider: { ...unverifiedRollback.restoration_run.provider, selected_count: 1 } } }), contract), /provider failure is incomplete/);
  assert.throws(() => verifyUnverifiedRollbackTerminal(unverifiedTerminal.slice(0, -1).concat({ ...unverifiedRollback, restoration_run: { ...unverifiedRollback.restoration_run, artifacts: { ...unverifiedRollback.restoration_run.artifacts, "accrue-host-phase15-screenshots": false } } }), contract), /required artifact/);
  assert.throws(() => verifyUnverifiedRollbackTerminal(unverifiedTerminal.filter((record) => record.kind !== "restoration_dispatch_transport"), contract), /transport identity is inconsistent/);
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
  const comparison = records.find((record) => record.kind === "comparison");
  const post = records.filter((record) => record.kind === "post_run").sort((a, b) => a.run_id - b.run_id);
  const control = records.find((record) => record.kind === "negative_control");
  const pending = records.find((record) => record.kind === "decision_pending");
  const durations = post.map((record) => record.duration_seconds).sort((a, b) => a - b);
  const median = durations[Math.floor(durations.length / 2)];
  const range = `${durations[0]}-${durations.at(-1)}s`;
  return `# Phase 227 critical-path comparison\n\n## Current fact\n\n- Frozen Phase 226 median: ${comparison.before_median_seconds}s; p95: ${comparison.before_p95_seconds}s\n- Candidate median: ${median}s; range: ${range}; keep threshold: ${comparison.threshold_seconds}s\n- Event class: ${post[0].event_class}; samples: ${post.length}; fingerprint: ${post[0].fingerprint}\n\n## Decision\n\n- state: \`${pending.state}\`\n- owner: ${pending.owner}\n- next command: \`${pending.next_command}\`\n\n## Immutable observations\n\n| Run | Staged duration | Removed host DAG wait | Workflow context |\n| --- | ---: | ---: | --- |\n${post.map((record) => `| [${record.run_id}](${record.run_url}) | ${record.duration_seconds}s | ${record.host_dag_wait_seconds}s | ${record.workflow_duration_seconds}s |`).join("\n")}\n\n## Controlled negative control\n\n- [run](${control.run_url}) — marker \`${control.annotation_marker}\`; annotation sweep: failure; host/browser: complete.\n- Temporary control branch was removed after live verification; artifact presence/absence is retained in NDJSON.\n\n## Evidence boundary\n\nPhase 226 inputs remain frozen; this report is rendered deterministically from \`227-CI-CRITICAL-PATH.ndjson\`.\n`;
}

const supportedRequireFlags = new Set(["--require-preflight", "--require-kept", "--require-negative-control", "--require-final-decision", "--require-rollback-verified"]);
for (const argument of process.argv.slice(2)) {
  if (argument.startsWith("--require-") && !supportedRequireFlags.has(argument)) fail(`unsupported require flag: ${argument}`);
}

if (process.argv.includes("--fixtures")) verifyFixtures();
const workflow = option("--workflow");
const contractFile = option("--contract") || path.join(phase, "227-ci-contract.json");
if (workflow) verifyWorkflowContract(fs.readFileSync(workflow, "utf8"), readJson(contractFile));
if (process.argv.includes("--require-preflight")) {
  if (!workflow) fail("--require-preflight needs --workflow");
  verifyMeasurementPreflight(fs.readFileSync(workflow, "utf8"), readJson(contractFile));
}
if (process.argv.includes("--require-kept")) {
  const evidence = option("--evidence");
  if (!evidence) fail("--require-kept needs --evidence");
  const records = evidenceRecords(evidence);
  const result = verifyComparisonEvidence(records, readJson(contractFile), { expectedRepository: option("--expected-repository") });
  if (!result.keep) fail("evidence is rolled back");
}
if (process.argv.includes("--require-final-decision")) {
  const evidence = option("--evidence");
  if (!evidence) fail("--require-final-decision needs --evidence");
  verifyFinalDecision(evidenceRecords(evidence), readJson(contractFile), option("--expected-repository") || "szTheory/accrue");
}
if (process.argv.includes("--require-rollback-verified")) {
  const evidence = option("--evidence");
  if (!evidence) fail("--require-rollback-verified needs --evidence");
  verifyRollbackTerminal(evidenceRecords(evidence), readJson(contractFile), option("--expected-repository") || "szTheory/accrue");
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
  const repository = option("--expected-repository");
  if (records.some((record) => record.kind === "contract_correction")) {
    if (!repository || repository !== "szTheory/accrue") fail("--expected-repository must be szTheory/accrue for live verification");
    verifyLiveReclassifications(records, contract, repository);
    if (process.argv.includes("--require-final-decision") || process.argv.includes("--require-rollback-verified")) verifyLiveRollback(records, contract, repository, process.argv.includes("--require-rollback-verified"));
  } else {
    verifyLiveEvidence(records, contract, repository, process.argv.includes("--require-negative-control"), option("--control-branch"));
  }
  const rendered = option("--rendered");
  if (rendered && !records.some((record) => record.kind === "contract_correction") && fs.readFileSync(rendered, "utf8") !== renderCriticalPathEvidence(records)) fail("rendered report does not byte-match NDJSON render");
}
