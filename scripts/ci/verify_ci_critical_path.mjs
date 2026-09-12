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

const V3_BUDGET = "phase-227-gap-dispatch-false-v3";
const V3_PREFIX_LENGTH = ["negative_control", "exclusion", "negative_control", ...Array(9).fill("exclusion"), "decision_pending"].length;
const V3_PREFLIGHT_EVIDENCE_PATH = ".planning/phases/227-measured-critical-path-improvement/227-CANDIDATE-PREFLIGHT.json";
const V3_ACTIVATION_VALIDATOR_VERSION = "phase227-v3-activation-evidence-v1";

function v3Records(records, kind) { return records.filter((record) => record.kind === kind); }

function sha256(value) { return `sha256:${digest(value)}`; }

function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(",")} ]`;
  if (value && typeof value === "object") return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`).join(",")}}`;
  return JSON.stringify(value);
}

function verifyV3Activation(activation, evidencePath = V3_PREFLIGHT_EVIDENCE_PATH) {
  assert.deepEqual(Object.keys(activation).sort(), ["activated_at", "candidate_sha", "candidate_tree", "check_vector_sha256", "kind", "preflight_evidence_path", "preflight_evidence_sha256", "prohibited_invocation_log_sha256", "remote_effects", "validator_version", "wrapper_sha256"].sort(), "v3 activation schema differs");
  assert.equal(activation.remote_effects, "enabled", "v3 activation must explicitly enable remote effects");
  assert.equal(activation.preflight_evidence_path, V3_PREFLIGHT_EVIDENCE_PATH, "v3 activation preflight path differs");
  assert.equal(activation.validator_version, V3_ACTIVATION_VALIDATOR_VERSION, "v3 activation validator version differs");
  assert.match(activation.activated_at || "", /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, "v3 activation timestamp is invalid");
  assert.ok(typeof evidencePath === "string" && !path.isAbsolute(evidencePath), "v3 activation evidence path must be repository-relative");
  assert.equal(evidencePath, activation.preflight_evidence_path, "v3 activation did not use the declared preflight artifact");
  const evidenceBytes = fs.readFileSync(path.join(root, evidencePath));
  const preflight = verifyV3Preflight(JSON.parse(evidenceBytes), activation.candidate_sha, "candidate");
  assert.equal(activation.candidate_tree, preflight.candidate_tree, "v3 activation tree differs from preflight");
  assert.equal(activation.preflight_evidence_sha256, sha256(evidenceBytes), "v3 activation preflight digest differs");
  assert.equal(activation.wrapper_sha256, preflight.wrapper_sha256, "v3 activation wrapper digest differs from preflight");
  assert.equal(activation.wrapper_sha256, sha256(fs.readFileSync(path.join(root, "scripts/ci/preflight_phase227_candidate.sh"))), "v3 activation wrapper digest differs from the current wrapper");
  assert.equal(activation.check_vector_sha256, sha256(stableJson(preflight.check_results)), "v3 activation check-vector digest differs");
  assert.equal(activation.prohibited_invocation_log_sha256, sha256(""), "v3 activation prohibited-invocation log must be empty");
  return preflight;
}

function assertV3Prefix(records) {
  assert.deepEqual(records.slice(0, V3_PREFIX_LENGTH).map((record) => record.kind), ["negative_control", "exclusion", "negative_control", ...Array(9).fill("exclusion"), "decision_pending"], "historical ledger prefix changed");
  const v2 = records.find((record) => record.kind === "gap_budget_authorization" && record.budget_id === "phase-227-gap-dispatch-false-v2");
  assert.ok(v2, "closed v2 authority is missing");
  const v2Decision = records.find((record) => record.kind === "gap_decision");
  assert.equal(v2Decision?.state, "rollback_applied_unverified", "closed v2 authority changed");
}

function verifyV3Preflight(record, expectedSha, expectedState) {
  assert.deepEqual(Object.keys(record || {}).sort(), ["candidate_sha", "candidate_tree", "changed_files", "check_results", "expected_state", "kind", "parent_sha", "parent_tree", "remote_effects", "status", "wrapper_sha256"].sort(), "v3 preflight evidence schema differs");
  assert.equal(record.status, "passed", "v3 preflight did not pass");
  assert.equal(record.remote_effects, "none", "v3 preflight has remote effects");
  assert.equal(record.expected_state, expectedState, "v3 preflight state differs");
  assert.match(record.candidate_sha || "", /^[0-9a-f]{40}$/, "v3 preflight candidate SHA is invalid");
  if (expectedSha) assert.equal(record.candidate_sha, expectedSha, "v3 preflight candidate SHA differs");
  assert.match(record.candidate_tree || "", /^[0-9a-f]{40}$/, "v3 preflight candidate tree is invalid");
  assert.match(record.parent_sha || "", /^[0-9a-f]{40}$/, "v3 preflight parent SHA is invalid");
  assert.match(record.parent_tree || "", /^[0-9a-f]{40}$/, "v3 preflight parent tree is invalid");
  assert.ok(Array.isArray(record.changed_files) && record.changed_files.every((file) => typeof file === "string"), "v3 preflight changed-file vector is invalid");
  if (expectedState === "candidate") assert.deepEqual(record.changed_files, [".github/workflows/ci.yml"], "candidate preflight must contain only the workflow edge change");
  assert.match(record.wrapper_sha256 || "", /^sha256:[0-9a-f]{64}$/, "v3 preflight wrapper digest is invalid");
  assert.deepEqual(record.check_results, { node_syntax: "passed", node_tests: "passed", fixtures: "passed", workflow: "passed", accrue_format: "passed", accrue_test: "passed", prohibited_invocations: 0 }, "v3 preflight checks differ");
  return record;
}

export function verifyPreflightEvidence(evidence, candidateSha, expectedState) {
  return verifyV3Preflight(typeof evidence === "string" ? readJson(evidence) : evidence, candidateSha, expectedState);
}

function verifyGapV3Evidence(records, contract, expectedRepository, activationEvidencePath = V3_PREFLIGHT_EVIDENCE_PATH) {
  assertV3Prefix(records);
  const budgets = v3Records(records, "gap_budget_authorization_v3");
  assert.equal(budgets.length, 1, "v3 authorization must appear exactly once");
  const budget = budgets[0];
  assert.deepEqual(Object.keys(budget).sort(), ["authorized_at", "budget_id", "candidate_ceiling", "candidate_fingerprint", "candidate_provider_state", "candidate_run_attempt", "candidate_run_live_stripe", "closed_predecessors", "conditional_restoration_ceiling", "event_class", "existing_negative_control_run_id", "kind", "no_concurrency", "no_replacements", "no_reruns", "owner", "phase228_provider_evidence", "phase228_provider_outcome", "remote_effects", "repository", "stop_on_first_nonqualifying", "thresholds"].sort(), "v3 authorization schema differs");
  assert.equal(budget.budget_id, V3_BUDGET, "v3 budget id differs");
  assert.equal(budget.repository, expectedRepository, "v3 authorization repository differs");
  assert.equal(budget.event_class, "workflow_dispatch", "v3 event class differs");
  assert.equal(budget.candidate_run_live_stripe, false, "v3 candidate input differs");
  assert.equal(budget.candidate_run_attempt, 1, "v3 candidate attempt differs");
  assert.equal(budget.candidate_fingerprint, V3_BUDGET, "v3 fingerprint differs");
  assert.equal(budget.candidate_provider_state, "non_run", "v3 provider state differs");
  assert.equal(budget.candidate_ceiling, 3, "v3 candidate ceiling differs");
  assert.equal(budget.conditional_restoration_ceiling, 1, "v3 restoration ceiling differs");
  assert.deepEqual(budget.closed_predecessors, ["phase-227-dispatch-false-v1", "phase-227-gap-dispatch-false-v2"], "v3 predecessors differ");
  assert.equal(budget.no_reruns, true, "v3 must prohibit reruns");
  assert.equal(budget.no_replacements, true, "v3 must prohibit replacements");
  assert.equal(budget.no_concurrency, true, "v3 must prohibit concurrency");
  assert.equal(budget.remote_effects, "disabled", "v3 must start with remote effects disabled");
  assert.equal(budget.stop_on_first_nonqualifying, true, "v3 stop policy differs");
  assert.deepEqual(budget.thresholds, contract.thresholds, "v3 thresholds differ from frozen contract");
  assert.equal(budget.phase228_provider_outcome, "failed/selected_assertions_failed", "Phase 228 provider outcome must remain literal");
  assert.ok(Number.isSafeInteger(budget.existing_negative_control_run_id) && budget.existing_negative_control_run_id > 0, "v3 negative-control reference is invalid");

  const reservations = v3Records(records, "gap_v3_reservation");
  const activations = v3Records(records, "gap_v3_activation");
  const candidates = v3Records(records, "gap_v3_candidate_run");
  const decisions = v3Records(records, "gap_v3_decision");
  assert.ok(reservations.length <= budget.candidate_ceiling + budget.conditional_restoration_ceiling, "v3 reservation ceiling exceeded");
  assert.ok(candidates.length <= budget.candidate_ceiling, "v3 candidate ceiling exceeded");
  assert.ok(activations.length <= 1, "v3 activation is duplicated");
  assert.ok(decisions.length <= 1, "v3 decision is duplicated");
  assert.equal(reservations.filter((entry) => entry.status === "open").length <= 1, true, "v3 has duplicate open reservations");
  const reservationIds = new Set();
  for (const reservation of reservations) {
    assert.deepEqual(Object.keys(reservation).sort(), ["candidate_sha", "kind", "purpose", "reservation_id", "status"].sort(), "v3 reservation schema differs");
    assert.ok(["candidate", "restoration"].includes(reservation.purpose), "v3 reservation purpose differs");
    assert.ok(!reservationIds.has(reservation.reservation_id), "v3 reservation is duplicated"); reservationIds.add(reservation.reservation_id);
    assert.match(reservation.candidate_sha || "", /^[0-9a-f]{40}$/, "v3 reservation SHA is invalid");
    assert.ok(["open", "bound", "terminal"].includes(reservation.status), "v3 reservation status differs");
  }
  const candidateIds = new Set();
  for (const candidate of candidates) {
    assert.deepEqual(Object.keys(candidate).sort(), ["kind", "reservation_id", "run_attempt", "run_id", "sha", "state"].sort(), "v3 candidate schema differs");
    assert.ok(reservationIds.has(candidate.reservation_id), "v3 candidate was not reserved");
    assert.ok(!candidateIds.has(candidate.run_id), "v3 run id is duplicated"); candidateIds.add(candidate.run_id);
    assert.equal(candidate.run_attempt, 1, "v3 candidate is not attempt 1");
    assert.equal(candidate.state, "terminal", "v3 candidate is not terminal");
  }
  if (!activations.length) {
    assert.equal(reservations.length, 0, "v3 cannot reserve before activation");
    assert.equal(candidates.length, 0, "v3 cannot consume before activation");
    return { state: "authorized_pending_candidate", admitted_observations: 0, reserved: 0, consumed: 0 };
  }
  const activation = activations[0];
  verifyV3Activation(activation, activationEvidencePath);
  return { state: decisions.length ? decisions[0].state : "activated_pending_reservation", admitted_observations: candidates.length, reserved: reservations.length, consumed: candidates.length };
}

export function verifyFinalDecision(records, contract, expectedRepository = "szTheory/accrue", activationEvidencePath = V3_PREFLIGHT_EVIDENCE_PATH) {
  if (records.some((record) => record.kind === "gap_budget_authorization_v3" && record.budget_id === V3_BUDGET)) {
    return verifyGapV3Evidence(records, contract, expectedRepository, activationEvidencePath);
  }
  if (records.some((record) => record.kind === "gap_budget_authorization" && record.budget_id === "phase-227-gap-dispatch-false-v2")) {
    return verifyGapV2Evidence(records, contract, expectedRepository);
  }
  const admitted = correctedCandidateAdmissions(records, contract);
  if (admitted.length >= contract.run_budget.final_candidate_attempts) fail("rollback decision is inconsistent with a complete admitted cohort");
  const rollback = latestRecord(records, "rollback");
  if (!rollback || !["rollback_verified", "rollback_applied_unverified"].includes(rollback.state)) fail("terminal rollback decision is missing");
  if (rollback.state === "rollback_verified") verifyRollbackTerminal(records, contract, expectedRepository);
  else verifyUnverifiedRollbackTerminal(records, contract, expectedRepository);
  return { state: rollback.state, admitted_observations: admitted.length };
}

function verifyGapV2Evidence(records, contract, expectedRepository) {
  const prefixLength = ["negative_control", "exclusion", "negative_control", ...Array(9).fill("exclusion"), "decision_pending"].length;
  assert.deepEqual(records.slice(0, prefixLength).map((record) => record.kind), ["negative_control", "exclusion", "negative_control", ...Array(9).fill("exclusion"), "decision_pending"], "historical ledger prefix changed");
  const authorization = records.filter((record) => record.kind === "gap_budget_authorization");
  assert.equal(authorization.length, 1, "v2 authorization must appear exactly once");
  const budget = authorization[0];
  assert.deepEqual(Object.keys(budget).sort(), ["authorized_at", "budget_id", "candidate_ceiling", "candidate_fingerprint", "candidate_provider_state", "candidate_run_attempt", "candidate_run_live_stripe", "conditional_restoration_ceiling", "event_class", "existing_negative_control_run_id", "kind", "no_replacements", "no_reruns", "old_budget_id", "old_budget_immutable", "old_budget_observations", "owner", "phase228_provider_evidence", "phase228_provider_outcome", "repository", "thresholds"].sort(), "v2 authorization schema differs");
  assert.equal(budget.budget_id, "phase-227-gap-dispatch-false-v2", "v2 budget id differs");
  assert.equal(budget.repository, expectedRepository, "v2 authorization repository differs");
  assert.equal(budget.event_class, "workflow_dispatch", "v2 event class differs");
  assert.equal(budget.candidate_run_live_stripe, false, "v2 candidate input differs");
  assert.equal(budget.candidate_run_attempt, 1, "v2 candidate attempt differs");
  assert.equal(budget.candidate_fingerprint, contract.measurement_topology.candidate_fingerprint, "v2 fingerprint differs");
  assert.equal(budget.candidate_provider_state, "non_run", "v2 provider state differs");
  assert.equal(budget.candidate_ceiling, 3, "v2 candidate ceiling differs");
  assert.equal(budget.conditional_restoration_ceiling, 1, "v2 restoration ceiling differs");
  assert.equal(budget.no_reruns, true, "v2 must prohibit reruns");
  assert.equal(budget.no_replacements, true, "v2 must prohibit replacements");
  assert.equal(budget.old_budget_id, "phase-227-dispatch-false-v1", "v1 identity differs");
  assert.equal(budget.old_budget_immutable, true, "v1 must remain immutable");
  assert.equal(budget.old_budget_observations, 0, "v1 observations must not transfer");
  assert.deepEqual(budget.thresholds, contract.thresholds, "v2 thresholds differ from frozen contract");
  assert.equal(budget.phase228_provider_outcome, "failed/selected_assertions_failed", "Phase 228 provider outcome must remain literal");
  assert.equal(budget.phase228_provider_evidence, "../228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md", "Phase 228 evidence link differs");
  assert.ok(Number.isSafeInteger(budget.existing_negative_control_run_id) && budget.existing_negative_control_run_id > 0, "negative control reference is invalid");

  const candidates = records.filter((record) => record.kind === "gap_candidate_run");
  const preflights = records.filter((record) => record.kind === "gap_candidate_preflight");
  const decisions = records.filter((record) => record.kind === "gap_decision");
  assert.ok(candidates.length <= budget.candidate_ceiling, "v2 candidate budget exceeded");
  assert.ok(preflights.length <= 1, "v2 candidate preflight is duplicated");
  assert.ok(decisions.length <= 1, "v2 decision is duplicated");
  const candidateShas = new Set();
  const candidateIds = new Set();
  for (const candidate of candidates) {
    assert.equal(candidate.repository, expectedRepository, "v2 candidate repository differs");
    assert.ok(Number.isSafeInteger(candidate.run_id) && candidate.run_id > 0, "v2 candidate run id is invalid");
    assert.ok(!candidateIds.has(candidate.run_id), "v2 candidate run id is duplicated");
    candidateIds.add(candidate.run_id);
    requireRecordUrl(candidate, "run_url", immutableRunUrl(expectedRepository, candidate.run_id));
    assert.match(candidate.sha || "", /^[0-9a-f]{40}$/, "v2 candidate SHA is invalid");
    candidateShas.add(candidate.sha);
    assert.equal(candidate.run_attempt, budget.candidate_run_attempt, "v2 candidate attempt differs");
    assert.equal(candidate.event_class, budget.event_class, "v2 candidate event differs");
    assert.deepEqual(candidate.inputs, { run_live_stripe: false }, "v2 candidate input differs");
    assert.equal(candidate.fingerprint, budget.candidate_fingerprint, "v2 candidate fingerprint differs");
    assert.equal(candidate.provider_state, budget.candidate_provider_state, "v2 candidate provider state differs");
    assert.match(candidate.workflow_revision || "", /^sha256:[0-9a-f]{64}$/, "v2 candidate workflow revision is invalid");
    assert.ok(candidate.classification === "admitted_observation" || contract.failure_classes.includes(candidate.classification), "v2 candidate classification is invalid");
    if (candidate.classification === "admitted_observation") {
      assert.ok(contract.proof_vector.required_job_roles.every((role) => candidate.required_jobs?.[role]?.conclusion === "success" && typeof candidate.required_jobs[role].url === "string"), "v2 candidate required proof vector is incomplete");
      assert.equal(candidate.required_jobs?.playwright?.urls?.length, 3, "v2 candidate Playwright proof vector is incomplete");
      assert.equal(candidate.artifacts?.[contract.proof_vector.expected_artifacts[0]], true, "v2 candidate success artifact is missing");
      assert.deepEqual(candidate.advisory, contract.proof_vector.advisory_outcomes, "v2 candidate advisory outcomes differ");
      assert.equal(candidate.conclusion, "success", "v2 admitted candidate conclusion differs");
    } else {
      assert.ok(candidate.classification !== "admitted_observation" && typeof candidate.exclusion_reason === "string" && candidate.exclusion_reason.length > 0, "v2 excluded candidate must retain its reason");
    }
  }
  assert.ok(candidateShas.size <= 1, "v2 candidates must share one candidate SHA");
  if (preflights.length) {
    const preflight = preflights[0];
    assert.deepEqual(Object.keys(preflight).sort(), ["candidate_fingerprint", "candidate_provider_state", "candidate_run_attempt", "candidate_run_live_stripe", "candidate_workflow_revision", "kind", "repository", "sha_binding", "state"].sort(), "v2 preflight schema differs");
    assert.equal(preflight.repository, expectedRepository, "v2 preflight repository differs");
    assert.equal(preflight.state, "passed_unbound", "v2 preflight must remain unbound until the task commit exists");
    assert.equal(preflight.candidate_run_live_stripe, false, "v2 preflight input differs");
    assert.equal(preflight.candidate_run_attempt, 1, "v2 preflight attempt differs");
    assert.equal(preflight.candidate_fingerprint, budget.candidate_fingerprint, "v2 preflight fingerprint differs");
    assert.equal(preflight.candidate_provider_state, budget.candidate_provider_state, "v2 preflight provider state differs");
    assert.match(preflight.candidate_workflow_revision, /^sha256:[0-9a-f]{64}$/, "v2 preflight workflow revision is invalid");
    assert.equal(preflight.sha_binding, "Task 2 commit SHA is captured before the first dispatch; no evidence commit is eligible", "v2 preflight SHA binding differs");
  }
  if (!decisions.length) {
    return { state: candidates.length ? "candidate_observation_recorded" : "authorized_unspent", admitted_observations: candidates.length };
  }
  const decision = decisions[0];
  assert.deepEqual(Object.keys(decision).sort(), ["candidate_authority", "candidate_run_ids", "kind", "path02", "reason", "restoration_authority", "restored_workflow_revision", "state"].sort(), "v2 terminal decision schema differs");
  assert.ok(["kept", "rollback_verified", "rollback_applied_unverified"].includes(decision.state), "v2 terminal decision is invalid");
  if (decision.state === "kept") {
    assert.equal(candidates.length, 3, "kept v2 decision requires exactly three candidates");
    assert.equal(decision.path02, "satisfied", "kept decision must satisfy PATH-02");
    assert.ok(Number.isSafeInteger(decision.median_seconds) && decision.median_seconds <= budget.thresholds.keep_median_seconds, "kept decision misses the median threshold");
    assert.ok(candidates.every((candidate) => candidate.classification === "admitted_observation" && candidate.duration_seconds <= budget.thresholds.maximum_observation_seconds), "kept decision exceeds the maximum-observation threshold");
  } else {
    assert.equal(decision.path02, "unmet", "rollback decision must leave PATH-02 unmet");
    assert.deepEqual(decision.candidate_run_ids, candidates.map((candidate) => candidate.run_id), "rollback decision must bind every consumed candidate run");
    assert.equal(decision.candidate_authority, "closed", "rollback decision must close candidate authority");
    assert.equal(decision.restoration_authority, "closed_unspent", "rollback decision must close unspent restoration authority");
    assert.equal(decision.restored_workflow_revision, `sha256:${contract.workflow_compatibility.restored_sha256}`, "rollback decision must bind the exact inverse workflow");
    assert.match(decision.reason, /required release lane/i, "rollback decision must state the required release-lane failure");
  }
  return { state: decision.state, admitted_observations: candidates.length };
}

function verifyLiveGapV2Candidates(records, contract, repository) {
  const candidates = records.filter((record) => record.kind === "gap_candidate_run");
  for (const record of candidates) {
    const run = api(`repos/${repository}/actions/runs/${record.run_id}`);
    if (run.head_sha !== record.sha || run.run_attempt !== 1 || run.event !== "workflow_dispatch" || run.conclusion !== record.conclusion) fail(`live v2 candidate facts differ for ${record.run_id}`);
    if (workflowRevision(repository, record.sha) !== record.workflow_revision) fail(`live v2 candidate workflow revision differs for ${record.run_id}`);
    const jobs = api(`repos/${repository}/actions/runs/${record.run_id}/attempts/1/jobs?filter=all&per_page=100`).jobs;
    if (!Array.isArray(jobs)) fail(`live v2 candidate jobs are unavailable for ${record.run_id}`);
    if (record.classification !== "admitted_observation") continue;
    for (const role of contract.proof_vector.required_job_roles) {
      const proof = record.required_jobs?.[role];
      if (role.startsWith("playwright-e2e-shard-")) {
        const url = proof?.url;
        verifyRecordedJob(jobs, repository, record.run_id, { url, conclusion: "success" }, role);
      } else verifyRecordedJob(jobs, repository, record.run_id, proof, role);
    }
    const playwright = record.required_jobs?.playwright;
    for (const url of playwright?.urls || []) verifyRecordedJob(jobs, repository, record.run_id, { url, conclusion: "success" }, "Playwright");
    const names = new Set(api(`repos/${repository}/actions/runs/${record.run_id}/artifacts?per_page=100`).artifacts.map((artifact) => artifact.name));
    if (!names.has(contract.proof_vector.expected_artifacts[0])) fail(`live v2 candidate lacks success artifact: ${record.run_id}`);
  }
  return true;
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
  if (records.some((record) => record.kind === "gap_budget_authorization_v3" && record.budget_id === V3_BUDGET)) {
    const result = verifyGapV3Evidence(records, contract, "szTheory/accrue");
    const budget = records.find((record) => record.kind === "gap_budget_authorization_v3");
    return `# Phase 227 critical-path v3 authorization\n\n## Current fact\n\n- state: \`${result.state}\`\n- owner: ${budget.owner}\n- budget: \`${budget.budget_id}\`\n- PATH-02: \`unmet\`\n- candidate slots reserved: ${result.reserved}/${budget.candidate_ceiling}\n- candidate slots consumed: ${result.consumed}/${budget.candidate_ceiling}\n- restoration slots consumed: 0/${budget.conditional_restoration_ceiling}\n- remote effects: \`${budget.remote_effects}\`\n- old budgets: \`${budget.closed_predecessors.join("\`, \`")}\` remain closed and supply zero v3 observations\n- next command: \`node scripts/ci/preflight_phase227_candidate.sh --commit <candidate-sha> --expected-state candidate --evidence-out .planning/phases/227-measured-critical-path-improvement/227-CANDIDATE-PREFLIGHT.json\`\n\nThis is local preparation, not live proof. Candidate authority is finite: exactly three unique attempt-1 manual-false runs at one committed candidate after an append-only activation binds passing exact-tree preflight evidence. Reruns, replacements, and concurrency are prohibited; restoration is one conditional inverse-only slot.\n`;
  }
  if (records.some((record) => record.kind === "gap_budget_authorization" && record.budget_id === "phase-227-gap-dispatch-false-v2")) {
    const result = verifyGapV2Evidence(records, contract, "szTheory/accrue");
    const budget = records.find((record) => record.kind === "gap_budget_authorization");
    const candidates = records.filter((record) => record.kind === "gap_candidate_run");
    const decision = latestRecord(records, "gap_decision");
    const next = decision ? "none" : "node scripts/ci/verify_ci_critical_path.mjs --verify-workflow --workflow .github/workflows/ci.yml --contract .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json";
    const restoration = decision ? (decision.restoration_authority === "closed_unspent" ? 0 : 1) : 0;
    return `# Phase 227 critical-path v2 experiment\n\n## Current fact\n\n- state: \`${result.state}\`\n- owner: ${budget.owner}\n- budget: \`${budget.budget_id}\`\n- candidate slots consumed: ${candidates.length}/${budget.candidate_ceiling}\n- restoration slots consumed: ${restoration}/${budget.conditional_restoration_ceiling}\n- old budget: \`${budget.old_budget_id}\` remains immutable and supplies zero v2 observations\n- Phase 228 provider outcome: \`${budget.phase228_provider_outcome}\` (linked separately; never a candidate)\n- next command: \`${next}\`\n\nThe only candidate event is attempt-1 \`workflow_dispatch\` with \`run_live_stripe: false\`, fingerprint \`${budget.candidate_fingerprint}\`, and provider state \`${budget.candidate_provider_state}\`. Reruns and replacements are prohibited. Keep requires exactly three valid independent observations; an unspent authorization cannot satisfy PATH-02.\n${decision ? `\n## Terminal decision\n\n- state: \`${decision.state}\`\n- PATH-02: \`${decision.path02 || "satisfied"}\`\n- candidate authority: \`${decision.candidate_authority}\`\n- restoration authority: \`${decision.restoration_authority}\`\n- exact inverse workflow: \`${decision.restored_workflow_revision}\`\n` : ""}`;
  }
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
  if (records.some((record) => record.kind === "gap_budget_authorization_v3" && record.budget_id === V3_BUDGET)) {
    verifyGapV3Evidence(records, contract, "szTheory/accrue");
    return;
  }
  if (records.some((record) => record.kind === "gap_budget_authorization" && record.budget_id === "phase-227-gap-dispatch-false-v2")) {
    verifyGapV2Evidence(records, contract, "szTheory/accrue");
    return;
  }
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
  const actions = new Set(["--fixtures", "--verify-workflow", "--verify-evidence", "--render-evidence", "--verify-live-actions", "--verify-preflight-evidence"]);
  const values = new Set(["--workflow", "--workflow-fixture", "--contract", "--evidence", "--rendered", "--expected-repository", "--expected-state", "--control-branch", "--preflight-evidence", "--candidate-sha"]);
  const modifiers = new Set(["--require-final-decision", "--require-kept", "--require-rollback-verified", "--require-negative-control", "--require-no-remote-effects"]);
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
    "--verify-workflow": new Set(["--workflow", "--contract", "--expected-state"]),
    "--verify-evidence": new Set(["--evidence", "--contract", "--expected-repository", "--rendered", "--require-final-decision", "--require-kept", "--require-rollback-verified"]),
    "--render-evidence": new Set(["--evidence", "--contract", "--expected-repository", "--rendered"]),
    "--verify-preflight-evidence": new Set(["--preflight-evidence", "--candidate-sha", "--expected-state", "--require-no-remote-effects"]),
    "--verify-live-actions": new Set(["--evidence", "--contract", "--expected-repository", "--rendered", "--control-branch", "--require-final-decision", "--require-kept", "--require-rollback-verified", "--require-negative-control"]),
  }[action];
  for (const optionName of [...seen.keys(), ...flags]) if (optionName !== action && !allowed.has(optionName)) fail(`${optionName} is not allowed with ${action}`);
  return { action, values: seen, flags };
}

function runCli(argv) {
  const cli = parseCli(argv);
  const contractFile = cli.values.get("--contract") || path.join(phase, "227-ci-contract.json");
  const contract = readJson(contractFile);
  if (cli.action === "--fixtures") return verifyFixtures(cli.values.get("--workflow-fixture"));
  if (cli.action === "--verify-preflight-evidence") {
    const evidence = cli.values.get("--preflight-evidence"); const candidateSha = cli.values.get("--candidate-sha"); const expectedState = cli.values.get("--expected-state");
    if (!evidence || !candidateSha || !expectedState || !cli.flags.has("--require-no-remote-effects")) fail("preflight verification requires evidence, SHA, state, and --require-no-remote-effects");
    return verifyPreflightEvidence(evidence, candidateSha, expectedState);
  }
  if (cli.action === "--verify-workflow") {
    const workflow = cli.values.get("--workflow"); if (!workflow) fail("--verify-workflow requires --workflow");
    const result = verifyWorkflowContract(fs.readFileSync(workflow, "utf8"), contract);
    const expectedState = cli.values.get("--expected-state");
    if (expectedState && result.state !== expectedState) fail(`workflow state ${result.state} differs from expected ${expectedState}`);
    return result;
  }
  const evidence = cli.values.get("--evidence"); if (!evidence) fail(`${cli.action} requires --evidence`);
  const records = evidenceRecords(evidence);
  const repository = cli.values.get("--expected-repository") || "szTheory/accrue";
  if (cli.action === "--verify-evidence") {
    const result = verifyFinalDecision(records, contract, repository);
    if (cli.flags.has("--require-kept") && result.state !== "kept") fail("v2 terminal decision is not kept");
    const rendered = cli.values.get("--rendered");
    if (rendered && fs.readFileSync(rendered, "utf8") !== renderCriticalPathEvidence(records)) fail("rendered report does not byte-match NDJSON render");
    return result;
  }
  if (cli.action === "--render-evidence") {
    const rendered = cli.values.get("--rendered"); if (!rendered) fail("--render-evidence requires --rendered");
    const output = renderCriticalPathEvidence(records); if (fs.readFileSync(rendered, "utf8") !== output) fail("rendered report does not byte-match NDJSON render");
    return true;
  }
  if (records.some((record) => record.kind === "gap_budget_authorization" && record.budget_id === "phase-227-gap-dispatch-false-v2")) {
    const result = verifyGapV2Evidence(records, contract, repository);
    if (cli.flags.has("--require-kept") && result.state !== "kept") fail("v2 terminal decision is not kept");
    verifyLiveGapV2Candidates(records, contract, repository);
    if (cli.flags.has("--require-final-decision") && !records.some((record) => record.kind === "gap_decision")) fail("v2 terminal decision is missing");
    return true;
  }
  if (records.some((record) => record.kind === "contract_correction")) {
    verifyLiveReclassifications(records, contract, repository);
    if (cli.flags.has("--require-final-decision") || cli.flags.has("--require-rollback-verified")) verifyLiveRollback(records, contract, repository, cli.flags.has("--require-rollback-verified"));
  } else verifyLiveEvidence(records, contract, repository, cli.flags.has("--require-negative-control"), cli.values.get("--control-branch"));
  return true;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) runCli(process.argv.slice(2));
