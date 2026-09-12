import assert from "node:assert/strict";
import fs from "node:fs";
import { spawnSync } from "node:child_process";
import test from "node:test";
import crypto from "node:crypto";
import { verifyComparisonEvidence, verifyFinalDecision, verifyPreflightEvidence } from "./verify_ci_critical_path.mjs";

const phase = ".planning/phases/227-measured-critical-path-improvement";
const contract = JSON.parse(fs.readFileSync(`${phase}/227-ci-contract.json`, "utf8"));
const fixtures = JSON.parse(fs.readFileSync(`${phase}/fixtures/ci-critical-path-cases.json`, "utf8"));

test("rejects forged duplicate push cohort through public verification", () => {
  assert.throws(
    () => verifyComparisonEvidence(fixtures.forged_keep_evidence, contract, fixtures.context),
    /workflow_dispatch|unique|required job|schema fields/,
  );
});

test("rejects a CLI invocation with no declared action", () => {
  const result = spawnSync(process.execPath, ["scripts/ci/verify_ci_critical_path.mjs"], { encoding: "utf8" });
  assert.notEqual(result.status, 0, "a no-action verifier invocation must fail closed");
});

test("requires a kept decision when requested", () => {
  const rollbackOnlyEvidence = fs.mkdtempSync("/tmp/phase227-v2-rollback-");
  const evidencePath = `${rollbackOnlyEvidence}/evidence.ndjson`;
  const records = fs.readFileSync(`${phase}/227-CI-CRITICAL-PATH.ndjson`, "utf8")
    .trim()
    .split("\n")
    .map(JSON.parse)
    .filter((record) => !record.kind.startsWith("gap_v3_") && record.kind !== "gap_budget_authorization_v3");
  fs.writeFileSync(evidencePath, `${records.map((record) => JSON.stringify(record)).join("\n")}\n`);
  const result = spawnSync(process.execPath, [
    "scripts/ci/verify_ci_critical_path.mjs",
    "--verify-evidence",
    "--evidence", evidencePath,
    "--contract", `${phase}/227-ci-contract.json`,
    "--expected-repository", "szTheory/accrue",
    "--require-kept",
  ], { encoding: "utf8" });
  fs.rmSync(rollbackOnlyEvidence, { recursive: true, force: true });
  assert.notEqual(result.status, 0, "the recorded rollback terminal must not satisfy a kept-only request");
  assert.match(result.stderr, /terminal decision is not kept/, "the verifier must reject rollback as non-kept, not reject the modifier itself");
});

test("keeps v3 authority unspent until a matching preflight activation", () => {
  const history = fs.readFileSync(`${phase}/227-CI-CRITICAL-PATH.ndjson`, "utf8").trim().split("\n").map(JSON.parse).filter((record) => !record.kind.startsWith("gap_v3_") && record.kind !== "gap_budget_authorization_v3");
  const budget = { kind: "gap_budget_authorization_v3", budget_id: "phase-227-gap-dispatch-false-v3", authorized_at: "2026-09-12T00:00:00Z", owner: "maintainer", repository: "szTheory/accrue", event_class: "workflow_dispatch", candidate_run_live_stripe: false, candidate_run_attempt: 1, candidate_fingerprint: "phase-227-gap-dispatch-false-v3", candidate_provider_state: "non_run", candidate_ceiling: 3, conditional_restoration_ceiling: 1, no_reruns: true, no_replacements: true, no_concurrency: true, remote_effects: "disabled", stop_on_first_nonqualifying: true, closed_predecessors: ["phase-227-dispatch-false-v1", "phase-227-gap-dispatch-false-v2"], existing_negative_control_run_id: 31660617339, phase228_provider_evidence: "../228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md", phase228_provider_outcome: "failed/selected_assertions_failed", thresholds: contract.thresholds };
  assert.deepEqual(verifyFinalDecision([...history, budget], contract), { state: "authorized_pending_candidate", admitted_observations: 0, reserved: 0, consumed: 0 });
  assert.throws(() => verifyFinalDecision([...history, budget, { kind: "gap_v3_reservation", reservation_id: "r1", purpose: "candidate", candidate_sha: "a".repeat(40), status: "open" }], contract), /reservation schema differs/);
  const evidencePath = `${phase}/227-CANDIDATE-PREFLIGHT.json`;
  const evidenceBytes = fs.readFileSync(evidencePath);
  const preflight = JSON.parse(evidenceBytes);
  assert.equal(verifyPreflightEvidence(preflight, preflight.candidate_sha, "candidate").remote_effects, "none");
  const sha256 = (value) => `sha256:${crypto.createHash("sha256").update(value).digest("hex")}`;
  const stableJson = (value) => Array.isArray(value) ? `[${value.map(stableJson).join(",")} ]` : value && typeof value === "object" ? `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`).join(",")}}` : JSON.stringify(value);
  const activation = { kind: "gap_v3_activation", activated_at: "2026-09-12T01:12:00Z", candidate_sha: preflight.candidate_sha, candidate_tree: preflight.candidate_tree, remote_effects: "enabled", preflight_evidence_path: evidencePath, preflight_evidence_sha256: sha256(evidenceBytes), wrapper_sha256: preflight.wrapper_sha256, check_vector_sha256: sha256(stableJson(preflight.check_results)), prohibited_invocation_log_sha256: sha256(""), validator_version: "phase227-v3-activation-evidence-v1" };
  assert.deepEqual(verifyFinalDecision([...history, budget, activation], contract), { state: "activated_pending_reservation", admitted_observations: 0, reserved: 0, consumed: 0 });
  assert.throws(() => verifyFinalDecision([...history, budget, { ...activation, preflight_evidence_sha256: `sha256:${"0".repeat(64)}` }], contract), /preflight digest differs/);
});

test("v3 rejects duplicate consumption, incomplete kept evidence, and restoration-as-performance", () => {
  const history = fs.readFileSync(`${phase}/227-CI-CRITICAL-PATH.ndjson`, "utf8").trim().split("\n").map(JSON.parse).filter((record) => !record.kind.startsWith("gap_v3_") && record.kind !== "gap_budget_authorization_v3");
  const budget = { kind: "gap_budget_authorization_v3", budget_id: "phase-227-gap-dispatch-false-v3", authorized_at: "2026-09-12T00:00:00Z", owner: "maintainer", repository: "szTheory/accrue", event_class: "workflow_dispatch", candidate_run_live_stripe: false, candidate_run_attempt: 1, candidate_fingerprint: "phase-227-gap-dispatch-false-v3", candidate_provider_state: "non_run", candidate_ceiling: 3, conditional_restoration_ceiling: 1, no_reruns: true, no_replacements: true, no_concurrency: true, remote_effects: "disabled", stop_on_first_nonqualifying: true, closed_predecessors: ["phase-227-dispatch-false-v1", "phase-227-gap-dispatch-false-v2"], existing_negative_control_run_id: 31660617339, phase228_provider_evidence: "../228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md", phase228_provider_outcome: "failed/selected_assertions_failed", thresholds: contract.thresholds };
  const evidencePath = `${phase}/227-CANDIDATE-PREFLIGHT.json`; const bytes = fs.readFileSync(evidencePath); const preflight = JSON.parse(bytes);
  const sha256 = (value) => `sha256:${crypto.createHash("sha256").update(value).digest("hex")}`;
  const stableJson = (value) => Array.isArray(value) ? `[${value.map(stableJson).join(",")} ]` : value && typeof value === "object" ? `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`).join(",")}}` : JSON.stringify(value);
  const activation = { kind: "gap_v3_activation", activated_at: "2026-09-12T01:12:00Z", candidate_sha: preflight.candidate_sha, candidate_tree: preflight.candidate_tree, remote_effects: "enabled", preflight_evidence_path: evidencePath, preflight_evidence_sha256: sha256(bytes), wrapper_sha256: preflight.wrapper_sha256, check_vector_sha256: sha256(stableJson(preflight.check_results)), prohibited_invocation_log_sha256: sha256(""), validator_version: "phase227-v3-activation-evidence-v1" };
  const reservation = (ordinal, purpose = "candidate") => ({ kind: "gap_v3_reservation", reservation_id: `${purpose}-${ordinal}`, purpose, ordinal, nonce: `nonce-${purpose}-${ordinal}-1234`, status: "reserved", created_at: "2026-09-12T01:13:00Z", reconciled_at: "2026-09-12T01:13:01Z", repository: "szTheory/accrue", candidate_sha: preflight.candidate_sha, ref: purpose === "candidate" ? "phase-227-gap-dispatch-false-v3" : "phase-227-gap-dispatch-false-v3-restoration", event_class: "workflow_dispatch", inputs: { run_live_stripe: purpose === "restoration" }, run_attempt: 1, pre_dispatch_run_ids: [] });
  const consumption = (ordinal, purpose = "candidate") => ({ kind: "gap_v3_consumption", reservation_id: `${purpose}-${ordinal}`, run_id: 7000 + ordinal + (purpose === "restoration" ? 100 : 0), repository: "szTheory/accrue", sha: preflight.candidate_sha, ref: purpose === "candidate" ? "phase-227-gap-dispatch-false-v3" : "phase-227-gap-dispatch-false-v3-restoration", event_class: "workflow_dispatch", inputs: { run_live_stripe: purpose === "restoration" }, run_attempt: 1, dispatch_mode: "created", consumed_at: "2026-09-12T01:13:02Z" });
  const terminal = (ordinal, classification = "qualifying", purpose = "candidate") => { const c = consumption(ordinal, purpose); return { kind: purpose === "candidate" ? "gap_v3_candidate_run" : "gap_v3_restoration_run", reservation_id: c.reservation_id, run_id: c.run_id, repository: c.repository, run_url: `https://github.com/szTheory/accrue/actions/runs/${c.run_id}`, sha: c.sha, ref: c.ref, event_class: c.event_class, inputs: c.inputs, run_attempt: 1, state: "terminal", conclusion: classification === "qualifying" ? "success" : "failure", classification, provider_state: purpose === "candidate" ? "non_run" : "proved", workflow_revision: `sha256:${"a".repeat(64)}`, duration_seconds: 1600 + ordinal, host_dag_wait_seconds: 0, required_jobs: Object.fromEntries(contract.proof_vector.required_job_roles.map((role, index) => [role, { conclusion: classification === "qualifying" ? "success" : "failure", job_id: c.run_id * 100 + index, url: `https://github.com/szTheory/accrue/actions/runs/${c.run_id}/job/${c.run_id * 100 + index}` }])), artifacts: Object.fromEntries(contract.artifacts.map((name) => [name, contract.proof_vector.expected_artifacts.includes(name)])), advisory: contract.proof_vector.advisory_outcomes }; };
  const reservations = [reservation(1), reservation(2), reservation(3)]; const consumptions = [consumption(1), consumption(2), consumption(3)]; const terminals = [terminal(1), terminal(2), terminal(3)];
  const advisory = (entry) => ({ kind: "gap_v3_advisory_vector", run_id: entry.run_id, sigra: { job_id: entry.run_id * 100 + 90, url: `https://github.com/szTheory/accrue/actions/runs/${entry.run_id}/job/${entry.run_id * 100 + 90}`, conclusion: "success" }, parked_ratchet: { job_id: entry.run_id * 100 + 91, url: `https://github.com/szTheory/accrue/actions/runs/${entry.run_id}/job/${entry.run_id * 100 + 91}`, conclusion: "failure" } });
  const advisoryVectors = terminals.map(advisory);
  const kept = { kind: "gap_v3_decision", state: "kept", path02: "satisfied", candidate_authority: "closed", restoration_authority: "closed_unspent", candidate_ref_removed: true, candidate_run_ids: terminals.map((entry) => entry.run_id), median_seconds: 1602, workflow_state: "candidate", inverse_workflow_revision: `sha256:${contract.workflow_sha256}`, reason: "three qualifying observations" };
  assert.equal(verifyFinalDecision([...history, budget, activation, ...reservations, ...consumptions, ...terminals, ...advisoryVectors, kept], contract).state, "kept");
  assert.throws(() => verifyFinalDecision([...history, budget, activation, ...reservations, ...consumptions, consumptions[0], ...terminals, ...advisoryVectors, kept], contract), /consumed twice|dispatched twice/);
  assert.throws(() => verifyFinalDecision([...history, budget, activation, ...reservations, ...consumptions, terminals[0], terminals[1], advisoryVectors[0], advisoryVectors[1], kept], contract), /candidate IDs differ|exactly three/);
  const failed = terminal(3, "nonqualifying");
  assert.throws(() => verifyFinalDecision([...history, budget, activation, ...reservations, ...consumptions, terminals[0], terminals[1], failed, ...advisoryVectors, kept], contract), /nonqualifying candidate/);
  const restoreReservation = reservation(1, "restoration"); const restoreConsumption = consumption(1, "restoration"); const restoration = terminal(1, "restoration_only", "restoration");
  assert.throws(() => verifyFinalDecision([...history, budget, activation, ...reservations, ...consumptions, ...terminals, ...advisoryVectors, restoreReservation, restoreConsumption, restoration, advisory(restoration), kept], contract), /cannot include restoration/);
});

test("preflight wrapper has no remote-effect executable path", () => {
  const wrapper = fs.readFileSync("scripts/ci/preflight_phase227_candidate.sh", "utf8");
  assert.doesNotMatch(wrapper, /\b(?:gh|curl|wget|ssh|scp)\b|git\s+(?:push|fetch|pull|remote|ls-remote|update-ref)|workflow\s+(?:run|rerun)/, "wrapper must not contain a remote-capable command");
  assert.match(wrapper, /worktree add --detach/, "wrapper must use a detached worktree");
  assert.match(wrapper, /\^\[0-9a-f\]\{40\}\$/, "wrapper must require a full SHA");
});

test("preflight runtime sandbox records no prohibited invocation", () => {
  if (process.env.PHASE227_PREFLIGHT_NESTED === "1") return;
  const cache = process.env.PHASE227_MIX_CACHE;
  if (!cache) return;
  const sandbox = fs.mkdtempSync("/tmp/phase227-runtime-sandbox-");
  const bin = `${sandbox}/bin`; const log = `${sandbox}/prohibited.log`; const evidence = `${sandbox}/evidence.json`;
  fs.mkdirSync(bin);
  for (const command of ["gh", "curl", "wget", "ssh", "scp"]) fs.writeFileSync(`${bin}/${command}`, `#!/usr/bin/env bash\necho ${command}:\"$*\" >> \"$PHASE227_PROHIBITED_LOG\"\nexit 97\n`, { mode: 0o755 });
  fs.writeFileSync(`${bin}/git`, `#!/usr/bin/env bash\ncase \"$1\" in push|fetch|pull|remote|ls-remote|update-ref) echo git:\"$*\" >> \"$PHASE227_PROHIBITED_LOG\"; exit 97;; esac\nexec /usr/bin/git \"$@\"\n`, { mode: 0o755 });
  const sha = spawnSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
  const workflow = fs.readFileSync(".github/workflows/ci.yml", "utf8");
  const state = workflow.includes("needs: [docs-contracts-shift-left]") ? "candidate" : "inverse_rollback";
  const result = spawnSync("bash", ["scripts/ci/preflight_phase227_candidate.sh", "--commit", sha, "--expected-state", state, "--evidence-out", evidence], { encoding: "utf8", env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, PHASE227_MIX_CACHE: cache, PHASE227_PROHIBITED_LOG: log } });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(fs.existsSync(log) ? fs.readFileSync(log, "utf8") : "", "", "sandbox observed a prohibited invocation");
  assert.equal(JSON.parse(fs.readFileSync(evidence, "utf8")).remote_effects, "none");
});
